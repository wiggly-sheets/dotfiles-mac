local settings = require("default")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

local time = sbar.add("item", "time", {
	position = "right",
	padding_right = 18,
	update_freq = 1,
	width = 0,
	label = {
		color = colors.white,
		font = {
			family = settings.default,
			style = "Bold",
			size = 9,
		},
	},
	y_offset = 7,
})

local date = sbar.add("item", "date", {
	position = "right",
	y_offset = -5,
	padding_right = 14,
	update_freq = 60,
	label = {
		color = colors.white,
		font = {
			family = settings.default,
			style = "Medium",
			size = 8,
		},
	},
})

time:subscribe({ "forced", "routine", "system_woke" }, function()
	local up_value = os.date("%H:%M:%S %Z")
	time:set({ label = { string = up_value } })
end)

date:subscribe({ "forced", "routine", "system_woke" }, function()
	local down_value = os.date("%a %b %d %Y")
	date:set({ label = { string = down_value } })
end)

local left_click_script =
	[[osascript -e 'tell application "System Events" to tell process "Dato" to click menu bar item 1 of menu bar 2']]
local right_click_script =
	'osascript -e \'tell application "System Events" to tell process "ControlCenter" to click menu bar item 2 of menu bar 1\''

local middle_click_script = "open -a Calendar"

date:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(left_click_script)
	elseif env.BUTTON == "right" then
		sbar.exec(right_click_script)
	else
		sbar.exec(middle_click_script)
	end
end)

time:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(left_click_script)
	elseif env.BUTTON == "right" then
		sbar.exec(right_click_script)
	else
		sbar.exec(middle_click_script)
	end
end)

date:subscribe("mouse.entered", function()
	date:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 25,
			y_offset = 0,
		},
	})
end)

date:subscribe("mouse.entered", function()
	date:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 25,
			y_offset = 5,
		},
	})
end)

date:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	time:set({ background = { drawing = true, height = 20, color = colors.transparent } })
	date:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)

time:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	date:set({ background = { drawing = true, height = 10, color = colors.transparent } })
	time:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)
