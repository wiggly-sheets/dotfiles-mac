local settings = require("settings")

local divider2 = sbar.add("item", "divider2", {
	icon = {
		font = { family = settings.default },
		string = "│",
		drawing = true,
	},
	padding_left = 2,
	padding_right = 2,
	position = "left",
})
