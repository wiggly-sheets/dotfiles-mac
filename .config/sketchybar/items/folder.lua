local colors = require("colors")

local folder = sbar.add("item", "folder", {
	icon = {
		font = { size = 13.5 },
		string = "􀈖",
		color = colors.white,
	},
	padding_left = 2,
	padding_right = 2,
	position = "right",
	click_script = 'osascript -e \'tell application "System Events" to tell process "Default Folder X" to click menu bar item 1 of menu bar 2\'',
})
