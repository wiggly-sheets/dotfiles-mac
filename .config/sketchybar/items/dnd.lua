local dnd = sbar.add("item", "dnd", {
	icon = {
		drawing = false,
		font = { family = "SF Pro", size = 15 },
	},
	label = {
		drawing = true,
		string = "􀆺",
	},
	position = "right",
	script = "/Users/Zeb/.config/sketchybar/helpers/scripts/dnd.sh",
	click_script = 'osascript -e \'tell application "Shortcuts" to run shortcut "Toggle DND"\'',
	update_freq = 2,
	padding_right = 10,
	padding_left = 0,
})
