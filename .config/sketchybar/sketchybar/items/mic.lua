local colors = require("colors")
local icons = require("icons")

local mic_item = sbar.add("item", "mic", {
	icon = {
		drawing = true,
		string = icons.mic.on, -- Default unmuted mic icon.
		font = { family = "SF Pro", size = 13 },
		color = colors.white,
	},
	label = {
		drawing = true,
		width = "dynamic",
		padding_left = 5,
		padding_right = 0,
		string = "??", -- Default volume text.
		font = { family = "Inconsolata Nerd Font Mono" },
		color = colors.yellow,
	},
	position = "right",
	padding_left = 0,
	padding_right = -5,
	update_freq = 5,
	script = "~/.config/sketchybar/helpers/scripts/mic.sh",
	click_script = 'osascript -e \'tell application "System Events" to tell process "SoundSource" to click menu bar item 1 of menu bar 2\'',
})
