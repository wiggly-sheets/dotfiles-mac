local settings = require("default")
local colors = require("colors")
local icons = require("icons")

local click_script =
	'osascript -e \'tell application "System Events" to keystroke "t" using {command down, option down, control down}\''

local cpu_temp_item = sbar.add("item", "cpu_temp", {
	update_freq = 10,
	position = "right",
	padding_left = -51,
	y_offset = 10,
	icon = { string = icons.cpu, padding_left = 5, color = colors.white },
	label = { padding_left = 2, font = { family = settings.default, size = 10 } },

	click_script = click_script,
})

local gpu_temp_item = sbar.add("item", "gpu_temp", {
	update_freq = 10,
	position = "right",
	y_offset = -5,
	icon = { string = "􀧓", padding_left = 0, color = colors.white },
	label = { padding_left = 2, font = { family = settings.default, size = 12 } },

	click_script = click_script,
})

-- Function to update temperatures
local function update_temperatures()
	-- CPU temperature
	sbar.exec("smctemp -c -i25 -n180 -f", function(cpu_out)
		local cpu_temp = tonumber(cpu_out)
		local cpu_color = colors.green
		if cpu_temp > 70 then
			cpu_color = colors.red
		elseif cpu_temp > 60 then
			cpu_color = colors.orange
		elseif cpu_temp > 50 then
			cpu_color = colors.yellow
		elseif cpu_temp > 40 then
			cpu_color = colors.green
		else
			cpu_color = colors.blue
		end
		cpu_temp_item:set({
			label = {
				string = cpu_temp .. "°C",
				color = cpu_color,
				font = { family = settings.default, size = 8 },
			},
		})
	end)

	-- GPU temperature
	sbar.exec("smctemp -g -i25 -n180 -f", function(gpu_out)
		local gpu_temp = tonumber(gpu_out)
		local gpu_color = colors.green
		if gpu_temp > 70 then
			gpu_color = colors.red
		elseif gpu_temp > 60 then
			gpu_color = colors.orange
		elseif gpu_temp > 50 then
			gpu_color = colors.yellow
		elseif gpu_temp > 40 then
			gpu_color = colors.green
		else
			gpu_color = colors.blue
		end
		gpu_temp_item:set({
			label = {
				string = gpu_temp .. "°C",
				color = gpu_color,
				font = { family = settings.default, size = 8 },
			},
		})
	end)
end

-- Subscribe to events
cpu_temp_item:subscribe({ "routine", "forced", "system_woke" }, update_temperatures)
gpu_temp_item:subscribe({ "routine", "forced", "system_woke" }, update_temperatures)

-- ======== Hover effects ========
local function add_hover(item)
	item:subscribe("mouse.entered", function()
		gpu_temp_item:set({
			background = {
				drawing = true,
				color = 0x40FFFFFF,
				corner_radius = 15,
				height = 40,
				x_offset = 0,
				y_offset = 5,
			},
		})
	end)

	item:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
		cpu_temp_item:set({ background = { drawing = false } })
		gpu_temp_item:set({ background = { drawing = false } })
	end)
end

add_hover(cpu_temp_item)
add_hover(gpu_temp_item)
