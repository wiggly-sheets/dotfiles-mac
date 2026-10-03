local icons = require("helpers.icons")
local colors = require("colors")
local settings = require("default")
local graphs = require("helpers.graphs")

-- Execute the event provider binary which provides the event "network_update"
-- for the current network interface, which is fired every 2.0 seconds.

local function start_network_load()
	sbar.exec("route get default 2>/dev/null | awk '/interface: / {print $2}'", function(iface)
		iface = iface and iface:match("^%s*(.-)%s*$")
		if not iface or iface == "" then
			return
		end

		sbar.exec(
			string.format(
				"killall network_load >/dev/null 2>&1; sleep 0.1; "
					.. '[ -x "$CONFIG_DIR/helpers/event_providers/network_load/bin/network_load" ] && '
					.. "$CONFIG_DIR/helpers/event_providers/network_load/bin/network_load %s network_update 2.0 &",
				iface
			)
		)
	end)
end

-- run immediately at startup
start_network_load()

local network_up = sbar.add("item", "network1", {
	position = "right",
	label = {
		font = {
			family = settings.default,
			size = 8,
		},
		color = colors.blue,
		string = "??? Bps",
	},
	y_offset = 7,
})

local network_down = sbar.add("item", "network2", {
	position = "right",
	padding_right = -41,
	label = {
		font = {
			family = settings.default,
			size = 8,
		},
		color = colors.green,
		string = "??? Bps",
	},
	y_offset = -5,
})

local net_graph_up = sbar.add("graph", "net_graph_up", 42, {
	position = "right",
	icon = {
		font = {
			family = settings.default,
			size = 9,
		},
		string = icons.wifi.upload,
		color = colors.blue,
	},
	graph = {
		color = colors.blue,
	},
	background = {
		height = 10,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
	},
	y_offset = 7,
    padding_right = -3,
})

local net_graph_down = sbar.add("graph", "net_graph_down", 42, {
	position = "right",
	padding_right = -55,
	icon = {
		font = {
			family = settings.default,
			size = 9,
		},
		string = icons.wifi.download,
		color = colors.green,
	},
	graph = {
		color = colors.green,
	},
	background = {
		height = 10,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
	},
	y_offset = -5,
})

local normalize_up = graphs.make_graph_normalizer(512 * 1024) -- 512KB/s floor ceiling
local normalize_down = graphs.make_graph_normalizer(512 * 1024)

-- Convert rate strings like "123 Bps", "12 KBps", "1.2 MBps" into bytes/sec
local function parse_rate(rate_str)
	if not rate_str then
		return 0
	end

	local value, unit = rate_str:match("([%d%.]+)%s*(%a+)")
	value = tonumber(value) or 0

	if not unit then
		return value
	end

	unit = unit:lower()

	if unit:match("kb") then
		return value * 1024
	elseif unit:match("mb") then
		return value * 1024 * 1024
	elseif unit:match("gb") then
		return value * 1024 * 1024 * 1024
	else
		return value
	end
end

net_graph_up:subscribe("network_update", function(env)
	local up = parse_rate(env.upload)
	net_graph_up:push({ normalize_up(up) })
end)


net_graph_down:subscribe("network_update", function(env)
	local down = parse_rate(env.download)
	net_graph_down:push({ normalize_down(down) })
end)

network_up:subscribe("network_update", function(env)
	local upload_str = env.upload:gsub("Bps", "B/s")
	local download_str = env.download:gsub("Bps", "B/s")

	local up_color = (upload_str == "000 B/s") and colors.grey or colors.blue
	local down_color = (download_str == "000 B/s") and colors.grey or colors.green

	network_up:set({
		label = {
			string = upload_str,
			color = up_color,
		},
	})

	network_down:set({
		label = {
			string = download_str,
			color = down_color,
		},
	})

	net_graph_up:set({
		icon = { color = up_color },
	})

	net_graph_down:set({
		icon = { color = down_color },
	})
end)

-- Re-run when network state changes
net_graph_up:subscribe({ "wifi_change", "system_woke" }, start_network_load)

-- ======== Click handlers ========

local little_snitch_click_script = "open -a 'Little Snitch Network Monitor'"
local tailscale_click_script =
	'osascript -e \'tell application "System Events" to tell process "Tailscale" to click menu bar item 1 of menu bar 2\''
local shortcut_script =
	'osascript -e \'tell application "System Events" to keystroke "u" using {command down, option down, control down}\''

local function handle_arrow_click(env)
	if env.BUTTON == "left" then
		sbar.exec(shortcut_script)
	elseif env.BUTTON == "right" then
		sbar.exec(tailscale_click_script)
	else
		sbar.exec(little_snitch_click_script)
	end
end

network_up:subscribe("mouse.clicked", handle_arrow_click)
network_down:subscribe("mouse.clicked", handle_arrow_click)
net_graph_up:subscribe("mouse.clicked", handle_arrow_click)
net_graph_down:subscribe("mouse.clicked", handle_arrow_click)

-- ======== Shared network hover ========

local network_items = {
    network_up,
    network_down,
    net_graph_up,
    net_graph_down,
}

local function set_network_hover(color)
    for _, item in ipairs(network_items) do
        item:set({
            background = {
                drawing = true,
                color = color,
                corner_radius = 20,
                height = 10,
            },
        })
    end
end

local function show_network_hover()
    set_network_hover(colors.hover)
end

local function clear_network_hover()
    set_network_hover(colors.transparent)
end

for _, item in ipairs(network_items) do
    item:subscribe("mouse.entered", show_network_hover)

    item:subscribe({
        "mouse.exited",
        "mouse.entered.global",
        "mouse.exited.global",
    }, clear_network_hover)
end