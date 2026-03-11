return {
	black = 0xff1a1b26, -- tokyo night background
	white = 0xffc0caf5, -- main foreground text

	red = 0xfff7768e, -- official tokyo night red
	green = 0xff9ece6a, -- official tokyo night green
	blue = 0xff7aa2f7, -- main tokyo night blue
	yellow = 0xffe0af68, -- official tokyo night yellow
	orange = 0xffff9e64, -- orange accent
	magenta = 0xffbb9af7, -- purple accent

	grey = 0xff565f89, -- muted UI elements
	transparent = 0x00000000,

	-- keep your custom ones
	dnd = 0xffbb9af7,
	low_power = 0xff9ece6a,
	notifications = 0xffc82d3b,

	bar = {
		bg = 0xff24283b, -- tokyo night storm background
		border = 0xff414868,
	},

	popup = {
		bg = 0xc024283b,
		border = 0xff565f89,
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
