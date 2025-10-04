local colors = require("colors")

local media = sbar.add("item", "media", {
	padding_right = 5,
	icon = {
		font = { size = 13.5 },
		string = "􀫀",
		position = "right",
		color = colors.white,
	},
	position = "right",
	click_script = 'osascript -e \'tell application "System Events" to keystroke "o" using {command down, option down, control down}\'',
})
