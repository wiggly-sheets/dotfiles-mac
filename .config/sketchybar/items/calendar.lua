local colors = require("colors")
local icons = require("icons")

local calendar = sbar.add("item", "calendar", {
	position = "right",
	padding_right = 0,
	padding_left = 0,
	width = 5,
	label = {
		color = colors.white,
		font = {
			family = "SF Pro Display",
			size = 15,
		},
		-- SF Symbols is typically part of this font family
		string = icons.calendar, -- Assuming icons.calendar is set properly elsewhere
		y_offset = -1, -- Adjust for vertical alignment if needed
	},
	click_script = "cliclick kd:cmd,shift,ctrl,alt t:d",
})
