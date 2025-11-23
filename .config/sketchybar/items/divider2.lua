local settings = require("default")

local divider = sbar.add("item", "divider2", {
	icon = {
		font = { family = settings.default, size = 12 },
		string = "│",
		drawing = true,
	},
	padding_left = -2,
	padding_right = 0,
	position = "left",
})
