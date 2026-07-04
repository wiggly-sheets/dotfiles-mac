local settings = require("default")
local colors = require("colors")
local icons = require("helpers.icons")

local click_script =
	'osascript -e \'tell application "System Events" to keystroke "]" using {command down, option down, control down}\''

local cpu_temp = sbar.add("item", "cpu_temp", {
	update_freq = 10,
	position = "right",
	padding_left = -51,
	y_offset = 7,
	icon = { string = icons.cpu, padding_left = 5, color = colors.white },
	label = { padding_left = 2, font = { family = settings.default, size = 10 } },
	click_script = click_script,
})

local gpu_temp = sbar.add("item", "gpu_temp", {
	update_freq = 10,
	position = "right",
	y_offset = -6,
	icon = { string = icons.gpu, padding_left = 0, color = colors.white },
	label = { padding_left = 2, font = { family = settings.default, size = 12 } },
	click_script = click_script,
})

local function update_temperatures()
	-- CPU temperature
	sbar.exec("smctemp -c -i25 -n180 -f", function(cpu_out)
		local cpu_temperature = tonumber(cpu_out)
		local cpu_color = colors.green
		if cpu_temperature > 70 then
			cpu_color = colors.red
		elseif cpu_temperature > 60 then
			cpu_color = colors.orange
		elseif cpu_temperature > 50 then
			cpu_color = colors.yellow
		elseif cpu_temperature > 40 then
			cpu_color = colors.green
		else
			cpu_color = colors.blue
		end
		cpu_temp:set({
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
		local gpu_color = colors.green
		if gpu_temperature > 70 then
			gpu_color = colors.red
		elseif gpu_temperature > 60 then
			gpu_color = colors.orange
		elseif gpu_temperature > 50 then
			gpu_color = colors.yellow
		elseif gpu_temperature > 40 then
			gpu_color = colors.green
		else
			gpu_color = colors.blue
		end
		gpu_temp:set({
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
			height = 25,
			y_offset = 5,
		},
	})
end)

gpu_temp:subscribe("mouse.entered", function()
	gpu_temp:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 25,
			y_offset = 5,
		},
	})
end)

cpu_temp:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	gpu_temp:set({ background = { drawing = true, height = 20, color = colors.transparent } })
	cpu_temp:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)

gpu_temp:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	gpu_temp:set({ background = { drawing = true, height = 10, color = colors.transparent } })
	cpu_temp:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)
