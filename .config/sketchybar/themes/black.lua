return {
	black = 0xff000000,
	white = 0xff000000,
	red = 0xff000000,
	green = 0xff000000,
	blue = 0xff000000,
	yellow = 0xff000000,
	orange = 0xff000000,
	magenta = 0xff000000,
	grey = 0xff000000,
	transparent = 0x00000000,
	dnd = 0xffdee3ed,
	low_power = 0xff63981f,
	notifications = 0xffc82d3b,,

	bar = {
		bg = 0xff000000,
		border = 0xff000000,
	},
	popup = {
		bg = 0xff000000,
		border = 0xff000000,
	},
	bg1 = 0xff000000,
	bg2 = 0xff000000,

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
