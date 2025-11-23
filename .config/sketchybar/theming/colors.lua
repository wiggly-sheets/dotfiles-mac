return {
	black = 0xff000000,
	white = 0xffdee3ed,
	red = 0xffc82d3b,
	green = 0xff63981f,
	blue = 0xff018bad,
	yellow = 0xffe3cb17,
	orange = 0xffe3a500,
	magenta = 0xff7700e2,
	grey = 0xff787878,
	transparent = 0x00000000,
	dnd = 0xffb39df3,

	bar = {
		bg = 0xFF555555,
		border = 0xff2c2e34,
	},
	popup = {
		bg = 0xc02c2e34,
		border = 0xff7f8490,
	},
	bg1 = 0x00000000,
	bg2 = 0x00000000,

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
