local settings = require("settings")

local divider = sbar.add("item", "divider", {
	icon = {
		font = { family = settings.default, size = 10 },
		string = "│",
		drawing = true,
	},
	padding_left = 0,
	padding_right = 5,
	position = "left",
})
