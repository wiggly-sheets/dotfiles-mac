local colors = require("colors")

local display_item = sbar.add("item", "display", {
	icon = {
		drawing = true,
		-- Default icon, assuming a laptop if no external display is present.
		string = "􀟛",
		font = { family = "SF Pro", size = 12 },
		color = colors.white,
		padding_right = 5,
	},
	label = {
		drawing = true,
		font = { family = "Inconsolata Nerd Font Mono" },
		color = colors.yellow,
	},
	position = "right",
	update_freq = 5,
	script = "~/.config/sketchybar/helpers/scripts/display_percent.sh",
	click_script = 'osascript -e \'tell application "System Events" to keystroke "d" using {command down, option down, control down}\'',
})
