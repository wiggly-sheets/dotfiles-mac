local colors = require("colors")

-- === Defaults table ===
local default = {
	paddings = 1,
	font = {
		family = "Liga SFMono Nerd Font",
		size = 11,
		style_map = {
			Regular = "Regular",
			Medium = "Medium",
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
		size = default.font.size,
		style = default.font.style_map[style],
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
		corner_radius = 0,
		border_width = 0,
		color = colors.bar.bg,
		border_color = colors.bar.border,
		image = {
			corner_radius = 0,
			border_color = colors.transparent,
			border_width = 0,
		},
	},
	popup = {
		background = {
			border_width = 1,
			corner_radius = 20,
			border_color = colors.bar.border,
			color = colors.popup.bg,
			shadow = { drawing = false },
		},
		blur_radius = 50,
	},

	padding_left = default.paddings,
	padding_right = default.paddings,
	scroll_texts = true,
})

-- Return defaults in case other modules need them
return {
	-- font family string: item files pass it as `family = settings.default`
	default = default.font.family,
	-- gap between grouped items (cpu/ram); item files read it as `settings.group_paddings`
	group_paddings = 5,
}
