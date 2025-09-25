local colors = require("colors")
local media = sbar.add("item", "media", {
	icon = {
		font = { size = 14 },
		string = "􀫀",
		position = "right",
		color = colors.white,
	},
	label = { drawing = false, width = 0 },
	padding_left = -5,
	padding_right = 5,
	position = "right",
	click_script = 'osascript -e \'tell application "System Events" to tell process "NowPlaying" to click menu bar item 1 of menu bar 2',
})
