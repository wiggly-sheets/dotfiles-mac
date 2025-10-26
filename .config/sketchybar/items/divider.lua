local settings = require("settings")

local divider = sbar.add("item", "divider", {
	label = {
		font = { size = 12, family = settings.default },
		string = "|",
		drawing = true,
	},
	padding_left = -5,
})
