local colors = require("colors")

sbar.bar({

	display = "main",
	height = 30,
	color = colors.transparent,
	y_offset = 3,
	padding_right = 8,
	padding_left = 2,
	sticky = true,
	topmost = "window",
	margin = 2,
	shadow = true,
})
