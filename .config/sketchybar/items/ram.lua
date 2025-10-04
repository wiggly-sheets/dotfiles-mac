local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local ram = sbar.add("graph", "widgets.ram", 42, {
	position = "right",
	padding_right = -10,
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
