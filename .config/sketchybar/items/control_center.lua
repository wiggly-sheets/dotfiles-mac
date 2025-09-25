local colors = require("colors")

local control_center = sbar.add("item", "control_center", {
	position = "right",
	icon = {
		drawing = true,
		string = "􀜊",
		font = { family = "SF Pro", size = 13.5 },

		padding_left = 0,
		padding_right = -8,
		color = colors.white,
	},
	background = {
		drawing = false,
		padding_left = 0,
		padding_right = 0,
	},
	click_script = 'osascript -e \'tell application "System Events" to tell process "ControlCenter" to click menu bar item 2 of menu bar 1\'',
})
