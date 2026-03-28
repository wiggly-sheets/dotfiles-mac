---- Equivalent to the --bar domain
local colors = require("colors")

sbar.bar({

	display = "main",
	height = 30,
	color = 0x0A0A0A0D,
	y_offset = 6,
	blur_radius = 20,
	corner_radius = 60,
	padding_right = 0,
	padding_left = 0,
	topmost = "window",
	border_color = colors.grey,
	border_width = 1.0,
	margin = 6,
	shadow = "off",
})
