local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the event provider binary which provides the event "cpu_update" for
-- the cpu load data, which is fired every 3.0 seconds.
sbar.exec("killall cpu_load >/dev/null; $CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 3.0")

local cpu = sbar.add("graph", "widgets.cpu", 42, {
	position = "right",
	background = {
		height = 22,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
		padding_right = 0,
	},
	icon = { string = icons.cpu, padding_right = 3, padding_left = -2 },
	label = {
		string = "cpu ??%",
		font = {
			style = settings.default,
			size = 10.0,
		},
		align = "right",
		width = 0,
		y_offset = 10,
	},
	click_script = 'osascript -e \'tell application "System Events" to keystroke "c" using {command down, option down, control down}\'',

	updates = true,
	update_freq = 30,
})

cpu:subscribe("cpu_update", function(env)
	-- Also available: env.user_load, env.sys_load
	local load = tonumber(env.total_load)
	cpu:push({ load / 100. })

	local color = colors.green

	if load >= 90 then
		color = colors.red
	elseif load >= 70 then
		color = colors.orange
	elseif load >= 40 then
		color = colors.yellow
	end
	cpu:set({
		graph = { color = color },
		label = { color = color, string = "CPU " .. load .. "%" },
	})
end)

-- Background around the cpu item
sbar.add("bracket", "widgets.cpu.bracket", { cpu.name }, {
	background = { color = colors.bg1 },
})

-- Background around the cpu item
sbar.add("item", "widgets.cpu.padding", {
	position = "right",
	width = settings.group_paddings,
})

local ram = sbar.add("graph", "widgets.ram", 42, {
	position = "right",
	padding_right = -12,
	background = {
		height = 22,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
	},
	icon = { string = icons.ram, padding_right = 3 },
	label = {
		string = "ram ??%",
		font = {
			style = settings.default,
			size = 9.0,
		},
		align = "right",
		width = 0,
		y_offset = 10,
	},
	update_freq = 30,
	updates = true,
	click_script = 'osascript -e \'tell application "System Events" to keystroke "r" using {command down, option down, control down}\'',
})

sbar.add("bracket", "widgets.ram.bracket", { ram.name }, {
	background = { color = colors.bg1 },
})

sbar.add("item", "widgets.ram.padding", {
	position = "right",
	width = settings.group_paddings,
})
ram:subscribe({ "routine", "forced", "system_woke" }, function(env)
	sbar.exec("memory_pressure", function(output)
		local percentage = output:match("System%-wide memory free percentage: (%d+)")
		local load = 100 - tonumber(percentage)
		ram:push({ load / 100. })

		local color = colors.green
		if load >= 90 then
			color = colors.red
		elseif load >= 75 then
			color = colors.orange
		elseif load >= 50 then
			color = colors.yellow
		end

		ram:set({
			graph = { color = color },
			label = { color = color, string = "RAM " .. load .. "%" },
		})
	end)
end)
