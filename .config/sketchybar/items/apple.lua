local colors = require("colors")
local icons = require("icons")

local apple = sbar.add("item", {
	click_script = 'osascript -e \'tell application "System Events" to keystroke "a" using {command down, option down, control down}\'',
	icon = {
		font = { size = 14 },
		string = icons.apple,
		position = "left",
		padding_left = 7,
		padding_right = 2,
		color = colors.white,
	},
	label = { drawing = false, width = 0 },
	padding_left = 0,
	padding_right = 0,
	y_offset = 1,
	--click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0",
})
