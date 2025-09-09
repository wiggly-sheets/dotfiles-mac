local lowpowermode = sbar.add("item", "lowpowermode", {
	position = "right",
	label = {
		font = {
			family = "SF Pro",
			size = 12.0,
		},
		padding_right = 1,
		padding_left = -4,
		string = "􀋦",
	},
	script = "/Users/Zeb/.config/sketchybar/helpers/scripts/lowpowermode.sh",
	click_script = [[osascript -e 'tell application "Shortcuts" to run shortcut "Toggle Low Power"']],
	update_freq = 1,
})
