local settings = require("default")
local colors = require("colors")

local divider = sbar.add("item", "divider2", {
	icon = {
		font = { family = settings.default, size = 12 },
		string = "│",
		drawing = true,
		color = colors.white
	},
	padding_left = -2,
	padding_right = 0,
	position = "left",
})
