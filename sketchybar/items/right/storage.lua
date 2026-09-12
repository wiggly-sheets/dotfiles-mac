local settings = require("default")
local colors = require("colors")
local icons = require("helpers.icons")

local disk_icon = sbar.add("item", "storage_icon", {
	update_freq = 60,
	position = "right",
	padding_left = -32,
	padding_right = 10,
	y_offset = 7,
	icon = { font = { size = 14 } },
})

local disk_label = sbar.add("item", "storage_label", {
	update_freq = 60,
	position = "right",
	padding_left = 0,
	padding_right = 2,
	y_offset = -5,
	label = { font = { family = settings.default, size = 8 } },
})

local function update_disk()
	sbar.exec("/usr/local/bin/diskspace 2>&1", function(output)
		local available = tonumber(output:match("Available:%s*(%d+)")) or 0
		local total = tonumber(output:match("Total:%s*(%d+)")) or 1
		local used = total - available
		local percent = math.floor((used / total) * 100 + 0.5)

		local used_gb = math.floor(used / 1e9 + 0.5)
		local total_gb = math.floor(total / 1e9 + 0.5)

		local icon, color = icons.storage.empty, colors.green
		if percent >= 95 then
			icon, color = icons.storage.full, colors.red
		elseif percent >= 88 then
			icon, color = icons.storage.almost_full, colors.orange
		elseif percent >= 76 then
			icon, color = icons.storage.nearly_full, colors.orange
		elseif percent >= 64 then
			icon, color = icons.storage.mostly_full, colors.yellow
		elseif percent >= 52 then
			icon, color = icons.storage.half, colors.yellow
		elseif percent >= 40 then
			icon, color = icons.storage.one_third, colors.green
		elseif percent >= 28 then
			icon, color = icons.storage.one_quarter, colors.green
		elseif percent >= 16 then
			icon, color = icons.storage.low, colors.green
		end

		disk_icon:set({ icon = { string = icon, color = color } })
		disk_label:set({ label = { string = string.format("%d/%dG", used_gb, total_gb), color = color } })
	end)
end

local left_click_script =
	'osascript -e \'tell application "System Events" to keystroke "[" using {command down, option down, control down}\''

local function handle_disk_click(env)
	if env.BUTTON == "left" then
		sbar.exec(left_click_script)
    elseif env.BUTTON == "right" then
	sbar.exec("Open -a 'Activity Monitor'")
	end
end

disk_icon:subscribe("mouse.clicked", handle_disk_click)
disk_label:subscribe("mouse.clicked", handle_disk_click)
disk_icon:subscribe({ "routine", "forced", "system_woke" }, update_disk)
disk_label:subscribe({ "routine", "forced", "system_woke" }, update_disk)

disk_icon:subscribe("mouse.entered", function()
	disk_label:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			y_offset = 0,
		},
	})
	disk_icon:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			x_offset = 0,
		},
	})
end)

disk_label:subscribe("mouse.entered", function()
	disk_label:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			y_offset = 0,
		},
	})
	disk_icon:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			x_offset = 0,
		},
	})
end)

disk_icon:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	disk_label:set({ background = { drawing = true, height = 10, color = colors.transparent } })
	disk_icon:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)

disk_label:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	disk_label:set({ background = { drawing = true, height = 10, color = colors.transparent } })
	disk_icon:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)

update_disk()

local IO_UPDATE_FREQ = 2 -- seconds between polls
local MAX_MBPS = 300 -- color thresholds scale against this ceiling; tune to taste

-- Adaptive graph normalizer: EMA-smooths the raw rate, tracks a
-- rolling-window peak as the scale ceiling (so a burst dominates the
-- graph briefly, then ages out after GRAPH_WINDOW samples rather than
-- fading out slowly), and applies a power curve (not log) so mid/low
-- activity stays visibly distinct instead of being squashed near the
-- bottom or over-inflated by log's generosity near the top.
local GRAPH_ALPHA = 0.4 -- EMA smoothing factor (higher = more responsive, jumpier)
local GRAPH_WINDOW = 15 -- samples of "peak memory" (10 * 2s poll = ~20s)
local GRAPH_POWER = 0.45 -- <1 lifts low values; 1 = linear; higher = more log-like compression

local function make_graph_normalizer(min_ceiling)
	local ema = 0
	local window = {}
	return function(raw)
		ema = ema + GRAPH_ALPHA * (raw - ema)

		table.insert(window, ema)
		if #window > GRAPH_WINDOW then
			table.remove(window, 1)
		end

		local ceiling = min_ceiling
		for _, v in ipairs(window) do
			if v > ceiling then
				ceiling = v
			end
		end

		local ratio = math.min(ema / ceiling, 1)
		return math.max(ratio ^ GRAPH_POWER, 0.02)
	end
end

local normalize_read = make_graph_normalizer(5 * 1024 * 1024) -- 5MB/s floor ceiling
local normalize_write = make_graph_normalizer(5 * 1024 * 1024)

local disk_read = sbar.add("item", "disk_read", {
	position = "right",
	icon = {
		font = { family = settings.default, size = 8 },
        string = "R",
		padding_left = 2
	},
	label = {
		font = { family = settings.default, size = 8 },
		color = colors.green,
		string = "??? B/s",
	},
	y_offset = 7,
})

local disk_write = sbar.add("item", "disk_write", {
	position = "right",
	padding_right = -48,
	icon = {
		font = { family = settings.default, size = 8 },
        string = "W",
        padding_left = 5

	},
	label = {
		font = { family = settings.default, size = 8},
		color = colors.orange,
		string = "??? B/s",
	},
	y_offset = -5,
})

-- Read graph
local disk_read_graph = sbar.add("graph", "disk_read_graph", 42, {
	position = "right",
	graph = { color = colors.green },
	background = {
		height = 10,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
	},
	y_offset = 7,
	padding_right = -5,
	update_freq = IO_UPDATE_FREQ,
})

-- Write graph
local disk_write_graph = sbar.add("graph", "disk_write_graph", 42, {
	position = "right",
	padding_right = -49,
	graph = { color = colors.orange },
	background = {
		height = 10,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
	},
	y_offset = -5,
})

-- Formats a raw bytes/sec value into a fixed-width, zero-padded
-- string, e.g. "005B/s", "018K/s", "042M/s", "001G/s" — always 3
-- digits before the unit letter so the widget never shifts width as
-- the reading crosses a unit boundary, matching how network.lua's
-- provider pads its own "000 B/s"-style output.
local function format_bps(bytes_per_sec)
	local units = { "", "K", "M", "G" }
	local unit_index = 1
	local value = bytes_per_sec

	while value >= 1000 and unit_index < #units do
		value = value / 1000
		unit_index = unit_index + 1
	end

	local rounded = math.floor(value + 0.5)
	-- rounding can push e.g. 999.6 -> 1000; bump to the next unit so we
	-- never print a 4th digit
	if rounded >= 1000 and unit_index < #units then
		rounded = 1
		unit_index = unit_index + 1
	end

	return string.format("%03d%sB/s", rounded, units[unit_index])
end

local function io_color(mbps)
	local percent = (mbps / MAX_MBPS) * 100
	if percent >= 90 then
		return colors.red
	elseif percent >= 70 then
		return colors.orange
	elseif percent >= 40 then
		return colors.yellow
	end
	return colors.green
end

local last_read_bytes, last_write_bytes = nil, nil

local function update_disk_io()
	sbar.exec("ioreg -c IOBlockStorageDriver -r -w0", function(output)
		local read_bytes = tonumber(output:match('"Bytes %(Read%)"%s*=%s*(%d+)'))
		local write_bytes = tonumber(output:match('"Bytes %(Write%)"%s*=%s*(%d+)'))

		if not read_bytes or not write_bytes then
			return
		end

		if last_read_bytes and last_write_bytes then
			-- guard against negative deltas (counter reset / multiple drivers matched)
			local read_bps = math.max((read_bytes - last_read_bytes) / IO_UPDATE_FREQ, 0)
			local write_bps = math.max((write_bytes - last_write_bytes) / IO_UPDATE_FREQ, 0)

			local read_mbps = read_bps / 1e6
			local write_mbps = write_bps / 1e6

			local read_color = io_color(read_mbps)
			local write_color = io_color(write_mbps)

			-- label shows the raw instantaneous reading (matches network_up/
			-- network_down, which display env.upload/env.download unsmoothed)
			disk_read:set({
				icon = { color = read_color },
				label = { string = format_bps(read_bps), color = read_color },
			})
			disk_write:set({
				icon = { color = write_color },
				label = { string = format_bps(write_bps), color = write_color },
			})

			disk_read_graph:push({ normalize_read(read_bps) })
			disk_write_graph:push({ normalize_write(write_bps) })

			disk_read_graph:set({ graph = { color = read_color } })
			disk_write_graph:set({ graph = { color = write_color } })
		end

		last_read_bytes = read_bytes
		last_write_bytes = write_bytes
	end)
end

disk_read_graph:subscribe({ "routine", "forced", "system_woke" }, update_disk_io)
disk_write_graph:subscribe({ "routine", "forced", "system_woke" }, update_disk_io)

-- ======== Click handlers ========

disk_read:subscribe("mouse.clicked", handle_disk_click)
disk_write:subscribe("mouse.clicked", handle_disk_click)
disk_read_graph:subscribe("mouse.clicked", handle_disk_click)
disk_write_graph:subscribe("mouse.clicked", handle_disk_click)

-- ======== Hover effects ========
disk_read:subscribe("mouse.entered", function()
	disk_write:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			y_offset = 0,
		},
	})
	disk_read:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			x_offset = 0,
		},
	})
end)

disk_write:subscribe("mouse.entered", function()
	disk_read:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			y_offset = 0,
		},
	})
	disk_write:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			x_offset = 0,
		},
	})
end)

disk_read:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	disk_write:set({ background = { drawing = true, height = 10, color = colors.transparent } })
	disk_read:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)

disk_write:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	disk_read:set({ background = { drawing = true, height = 10, color = colors.transparent } })
	disk_write:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)

disk_write_graph:subscribe("mouse.entered", function()
	disk_read_graph:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			y_offset = 0,
		},
	})
	disk_write_graph:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			x_offset = 0,
		},
	})
end)

disk_read_graph:subscribe("mouse.entered", function()
	disk_read_graph:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			y_offset = 0,
		},
	})
	disk_write_graph:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			x_offset = 0,
		},
	})
end)

disk_write_graph:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	disk_read_graph:set({ background = { drawing = true, height = 10, color = colors.transparent } })
	disk_write_graph:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)

disk_read_graph:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	disk_write_graph:set({ background = { drawing = true, height = 20, color = colors.transparent } })
	disk_read_graph:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)

update_disk_io()