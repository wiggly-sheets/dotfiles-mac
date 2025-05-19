local colors = require("colors")

local control_center = sbar.add("item", "control_center", {
	position = "right",
	icon = {
		drawing = true,
		string = "􀜊", -- SF Symbol for control center (adjust as desired)
		font = { family = "SF Pro", size = 15 },

		padding_left = 0,
		padding_right = 15,
		color = colors.white,
	},
	background = {
		drawing = false,
		padding_left = 0,
		padding_right = 0,
	},
	click_script = "cliclick kd:fn t:c",
})
