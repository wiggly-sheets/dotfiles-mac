local colors = require("colors")

local control_center = sbar.add("item", "control_center", {
	position = "right",
	padding_right = 0,
	padding_left = 4,
	icon = {
		drawing = true,
		string = "􀜊",
		font = { size = 13.5 },

		color = colors.white,
	},
	background = {
		drawing = false,
	},
	click_script = 'osascript -e \'tell application "System Events" to tell process "ControlCenter" to click menu bar item 4 of menu bar 1\'',
})
