local dnd = sbar.add("item", "dnd", {
	label = {
		drawing = true,
		string = "􀆺",
		font = { size = 15 },
	},
	position = "right",
	script = "/Users/Zeb/.config/sketchybar/helpers/scripts/dnd.sh",
	click_script = 'osascript -e \'tell application "Shortcuts" to run shortcut "Toggle DND"\'',
	update_freq = 3,
	padding_right = 20,
})
