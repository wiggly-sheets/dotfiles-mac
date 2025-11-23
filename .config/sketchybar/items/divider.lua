local settings = require("default")

local divider = sbar.add("item", "divider", {
	icon = {
		font = { family = settings.default, size = 12 },
		string = "│",
		drawing = true,
	},
	padding_left = -2,
	padding_right = 4,
	position = "left",
})
