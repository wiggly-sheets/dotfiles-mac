local colors = require("colors")
local icons = require("icons")

local control_center = sbar.add("item", "control_center", {
	position = "right",
	padding_right = -5,
	padding_left = 0,
	icon = {
		drawing = true,
		string = icons.control_center,
		font = { size = 13 },

		color = colors.white,
	},
	background = {
		drawing = false,
	},
})
local left_click_script = "cliclick kd:fn t:c"

local right_click_script =
	'osascript -e \'tell application "System Events" to tell process "Only Switch" to click menu bar item 1 of menu bar 2\''

control_center:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(left_click_script)
	elseif env.BUTTON == "right" then
		sbar.exec(right_click_script)
	else
	end
end)

local function add_hover(item)
	item:subscribe("mouse.entered", function()
		item:set({
			background = {
				drawing = true,
				color = colors.hover,
				corner_radius = 20,
				height = 20,
				x_offset = -1,
			},
		})
	end)

	item:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
		item:set({ background = { drawing = false } })
	end)
end

add_hover(control_center)
