local colors = require("colors")

local folder = sbar.add("item", "folder", {
	icon = {
		font = { family = "SF Pro", size = 13.5},
		string = "􀈖",
		padding_left = 4,
		padding_right = -5,
		color = colors.white,
	},
	position = "right",
	click_script = 'osascript -e \'tell application "System Events" to tell process "Default Folder X" to click menu bar item 1 of menu bar 2\'',
})
