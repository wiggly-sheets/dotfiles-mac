local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
	display = "main",
	height = 40,
	color = colors.transparent,
	topmost = "window",
})
