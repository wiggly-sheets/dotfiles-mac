local settings = require("default")
local colors = require("colors")
local icons = require("helpers.icons")

local click_script =
	'osascript -e \'tell application "System Events" to keystroke "]" using {command down, option down, control down}\''

-- Temps are normalized against this range for the graph (°C).
-- Adjust TEMP_MIN/TEMP_MAX if your machine idles/throttles outside this band.
local TEMP_MIN = 30
local TEMP_MAX = 100

local function normalize_temp(t)
	local v = (t - TEMP_MIN) / (TEMP_MAX - TEMP_MIN)
	if v < 0 then
		v = 0
	elseif v > 1 then
		v = 1
	end
	return v
end

local function temp_color(t)
	if t > 70 then
		return colors.red
	elseif t > 60 then
		return colors.orange
	elseif t > 50 then
		return colors.yellow
	elseif t > 40 then
		return colors.green
	else
		return colors.blue
	end
end

local cpu_temp = sbar.add("graph", "cpu_temp", 42, {
	update_freq = 10,
	position = "right",
	padding_left = -92,
	y_offset = 7,
	background = {
		height = 10,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
		padding_right = 0,
	},
	icon = { string = icons.cpu, padding_left = 5, color = colors.white },
	label = { padding_left = 2, font = { family = settings.default, size = 10 } },
	click_script = click_script,
})

local gpu_temp = sbar.add("graph", "gpu_temp", 42, {
	update_freq = 10,
	position = "right",
	y_offset = -5,
	background = {
		height = 10,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
		padding_right = 0,
	},
	icon = { string = icons.gpu, padding_left = 0, color = colors.white },
	label = { padding_left = 2, font = { family = settings.default, size = 12 } },
	click_script = click_script,
})

local function update_temperatures()
	-- CPU temperature
	sbar.exec("smctemp -c -i25 -n180 -f", function(cpu_out)
		local cpu_temperature = tonumber(cpu_out)
		local cpu_color = temp_color(cpu_temperature)
		cpu_temp:push({ normalize_temp(cpu_temperature) })
		cpu_temp:set({
			graph = { color = cpu_color },
			label = {
				string = cpu_temperature .. "°C",
				color = cpu_color,
				font = { family = settings.default, size = 8 },
			},
		})
	end)

	-- GPU temperature
	sbar.exec("smctemp -g -i25 -n180 -f", function(gpu_out)
		local gpu_temperature = tonumber(gpu_out)
		local gpu_color = temp_color(gpu_temperature)
		gpu_temp:push({ normalize_temp(gpu_temperature) })
		gpu_temp:set({
			graph = { color = gpu_color },
			label = {
				string = gpu_temperature .. "°C",
				color = gpu_color,
				font = { family = settings.default, size = 8 },
			},
		})
	end)
end

cpu_temp:subscribe({ "routine", "forced", "system_woke" }, update_temperatures)
gpu_temp:subscribe({ "routine", "forced", "system_woke" }, update_temperatures)

cpu_temp:subscribe("mouse.entered", function()
	gpu_temp:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			y_offset = 0,
		},
	})
	cpu_temp:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			x_offset = 0,
		},
	})
end)

gpu_temp:subscribe("mouse.entered", function()
	gpu_temp:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			y_offset = 0,
		},
	})
	cpu_temp:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			x_offset = 0,
		},
	})
end)

cpu_temp:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	gpu_temp:set({ background = { drawing = true, height = 10, color = colors.transparent } })
	cpu_temp:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)

gpu_temp:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	gpu_temp:set({ background = { drawing = true, height = 10, color = colors.transparent } })
	cpu_temp:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)