local colors = require("colors")

local left_bracket = sbar.add("bracket", "left_bracket", { "apple", "add_space_button" }, {
	background = {
		drawing = true,
		color = colors.bar.bg,
		corner_radius = 60,
		height = 30,
		border_color = colors.bar.border,
		border_width = 1,
	},
	blur_radius = 20,
})

local right_bracket = sbar.add("bracket", "right_bracket", {
	"date",
	"toggle_items",
	"ram",
}, {
	background = {
		drawing = true,
		color = colors.bar.bg,
		corner_radius = 60,
		height = 30,
		border_color = colors.bar.border,
		border_width = 1,
	},
	blur_radius = 20,
})
