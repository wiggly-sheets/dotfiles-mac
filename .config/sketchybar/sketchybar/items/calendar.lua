local colors = require("colors")

local calendar = sbar.add("item", "calendar", {
	position = "right",
	padding_right = -1,
	padding_left = 0,
	width = 5,
	label = {
		color = colors.white,
		font = {
			family = "SF Pro Display",
			size = 15,
		},
		string = "􀉉",
	},
	click_script = "cliclick kd:cmd,shift,ctrl,alt t:d",
})
