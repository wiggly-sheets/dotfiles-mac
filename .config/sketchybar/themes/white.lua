return {
	black = 0xff000000,
	white = 0xffdee3ed,
	red = 0xffdee3ed,
	green = 0xffdee3ed,
	blue = 0xffdee3ed,
	yellow = 0xffdee3ed,
	orange = 0xffdee3ed,
	magenta = 0xffdee3ed,
	grey = 0xff787878,
	transparent = 0x00000000,
	dnd = 0xffdee3ed,
	low_power = 0xff63981f,
	notifications = 0xffc82d3b,

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
