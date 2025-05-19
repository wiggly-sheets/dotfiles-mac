local colors = require("colors")

-- Create the DND item in the bar
local dnd = sbar.add("item", "dnd", {
	icon = {
		drawing = false,
		font = { family = "SF Pro", size = 15 },
	},
	label = {
		drawing = true,
		font = { family = "SF Pro", size = 15 },
		string = "􀆹",
		color = colors.magenta,
	},
	position = "right",
	script = "/Users/Zeb/dotfiles/.config/sketchybar/helpers/scripts/dnd.sh",
	click_script = 'osascript -e \'tell application "Shortcuts" to run shortcut "Toggle DND"\'',
	update_freq = 10,
	padding_right = 0,
	padding_left = 0,
})
