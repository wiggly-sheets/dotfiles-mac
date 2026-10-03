local colors = require("colors")

local brackets = {}

-- The left bracket never changes; the right one depends on the active setup
-- because setups omit different trailing items.
function brackets.add(right_items)
	sbar.add("bracket", "left_bracket", { "apple", "add_space_button" }, {
		background = {
			drawing = true,
			color = colors.bar.bg,
			corner_radius = 12,
			height = 30,
			border_color = colors.bar.border,
			border_width = 1,
		},
		blur_radius = 5,
	})

	sbar.add("bracket", "right_bracket", right_items, {
		background = {
			drawing = true,
			color = colors.bar.bg,
			corner_radius = 12,
			height = 30,
			border_color = colors.bar.border,
			border_width = 1,
		},
		blur_radius = 5,
	})
end

return brackets
