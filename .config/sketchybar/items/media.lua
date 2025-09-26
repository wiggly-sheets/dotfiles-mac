local colors = require("colors")

local media = sbar.add("item", "media", {
	icon = {
		font = { size = 13.5 },
		string = "􀫀",
		position = "right",
		color = colors.white,
	},
	label = { drawing = false, width = 0 },
	padding_left = 0,
	padding_right = 5,
	position = "right",
	click_script = 'osascript -e \'tell application "System Events" to keystroke "o" using {command down, option down, control down}\'',
})
