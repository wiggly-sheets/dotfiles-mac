local colors = require("colors")

local control_center = sbar.add("item", "control_center", {
	position = "right",
	padding_right = 0,
	padding_left = 4,
	icon = {
		drawing = true,
		string = "􀜊",
		font = { size = 13.5 },

		color = colors.white,
	},
	background = {
		drawing = false,
	},
})
local left_click_script = "cliclick kd:fn t:c"

local right_click_script = "cliclick kd:fn t:s"

local middle_click_script = "open -a 'System Settings'"

control_center:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(left_click_script)
	elseif env.BUTTON == "right" then
		sbar.exec(right_click_script)
	else
		sbar.exec(middle_click_script)
	end
end)
