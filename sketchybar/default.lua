local colors = require("colors")

-- === Defaults table ===
local default = {
	paddings = 1,
	font = {
		family = "Liga SFMono Nerd Font",
		size = 11,
		style_map = {
			Regular = "Regular",
			Semibold = "Semibold",
			Bold = "Bold",
			Heavy = "Heavy",
		},
	},
}

-- Helper function to generate font tables
local function font(style)
	return {
		family = default.font.family,
		style = default.font.style_map[style or "Regular"],
		size = default.font.size,
	}
end

-- === sbar.default domain setup ===
sbar.default({
	updates = "when_shown",
	icon = {
		font = font("Regular"),
		color = colors.white,
		padding_left = default.paddings,
		padding_right = default.paddings,
		background = { image = { corner_radius = 0 } },
	},

	label = {
		font = font("Regular"),
		color = colors.white,
		padding_left = default.paddings,
		padding_right = default.paddings,
	},

	background = {
		height = 10,
		width = 10,
		corner_radius = 0,
		border_width = 0,
		color = colors.bar_bg,
		border_color = colors.bar.border,
		image = {
			corner_radius = 0,
			border_color = colors.transparent,
			border_width = 0,
			height = 10,
			width = 10,
		},
	},
	popup = {
		background = {
			border_width = 1,
			corner_radius = 20,
			border_color = colors.bar.border,
			color = colors.bar.bg,
			shadow = { drawing = false },
			blur_radius = 20,
		},
		blur_radius = 50,
	},

	padding_left = default.paddings,
	padding_right = default.paddings,
	scroll_texts = true,
})

-- Return defaults in case other modules need them
return {
	default = default,
	font = font,
	colors = colors,
}
