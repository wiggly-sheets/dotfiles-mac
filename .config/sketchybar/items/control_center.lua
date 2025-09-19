local colors = require("colors")

local control_center = sbar.add("item", "control_center", {
	position = "right",
	icon = {
		drawing = true,
		string = "􀜊", -- SF Symbol for control center (adjust as desired)
		font = { family = "SF Pro", size = 15 },

		padding_left = 0,
		padding_right = -5,
		color = colors.white,
	},
	background = {
		drawing = false,
		padding_left = 0,
		padding_right = 0,
	},
	click_script = 'osascript -e \'tell application "System Events" to tell process "ControlCenter" to click menu bar item 2 of menu bar 1\'',
})
