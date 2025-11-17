local settings = require("settings")
local colors = require("colors")

-- Equivalent to the --default domain
sbar.default({
	updates = "when_shown",
	icon = {
		font = {
			family = "Liga SFMono Nerd Font",
			style = settings.font.style_map["Regular"],
			size = 11.0,
		},
		color = colors.white,
		padding_left = settings.paddings,
		padding_right = settings.paddings,
		background = { image = { corner_radius = 0 } },
	},
	label = {
		font = {
			family = "Liga SFMono Nerd Font",
			style = settings.font.style_map["Regular"],
			size = 11.0,
		},
		color = colors.white,
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	background = {
		height = 10,
		width = 10,
		corner_radius = 0,
		border_width = 0,
		border_color = colors.transparent,
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
			border_color = colors.white,
			color = "0x0A0A0A0D",
			shadow = { drawing = false },
			blur_radius = 20,
		},
		blur_radius = 50,
	},
	padding_left = 5,
	padding_right = 5,
	scroll_texts = true,
})
