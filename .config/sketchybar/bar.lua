---- Equivalent to the --bar domain
local colors = require("colors")
sbar.bar({

	display = "main",
	height = 40,
	--	color = 0x0A0A0A0D,
	color = colors.transparent,
	blur_radius = 10,
	corner_radius = 0,
	padding_right = 0,
	padding_left = 0,
	topmost = "window",
	border_color = 0x00000000,
	border_width = 0.0,
	margin = 0,
})
