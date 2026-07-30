return {
	black = 0xff1a1b26,
	white = 0xffc0caf5,
	red = 0xffc0caf5,
	green = 0xffc0caf5,
	blue = 0xffc0caf5,
	yellow = 0xffc0caf5,
	orange = 0xffc0caf5,
	magenta = 0xffc0caf5,
	grey = 0xff787878,
	transparent = 0x00000000,
	hover = 0x40FFFFFF,
	dnd = 0xffc0caf5,
	low_power = 0xffc0caf5,
	notifications = 0xffc82d3b,
	bar = {
		bg = 0x4024283b,
		border = 0xff414868,
	},
	popup = {
		bg = 0xc024283b,
		border = 0xff565f89,
	},

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
