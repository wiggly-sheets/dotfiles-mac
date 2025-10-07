local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

local time = sbar.add("item", "time", {
	position = "right",
	padding_right = -4,
	update_freq = 1,
	width = 0,
	label = {
		color = colors.white,
		font = {
			family = settings.default,
			style = "Bold",
			size = 11,
		},
	},
	y_offset = 7,
})

local date = sbar.add("item", "date", {
	position = "right",
	y_offset = -5,
	padding_right = -13,
	update_freq = 60,
	label = {
		color = colors.white,
		font = {
			family = settings.default,
			style = "Bold",
			size = 11,
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

date:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(
			[[osascript -e 'tell application "System Events" to tell process "Dato" to click menu bar item 1 of menu bar 2']]
		)
	elseif env.BUTTON == "right" then
		sbar.exec("cliclick kd:fn t:n")
	end
end)

time:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(
			[[osascript -e 'tell application "System Events" to tell process "Dato" to click menu bar item 1 of menu bar 2']]
		)
	elseif env.BUTTON == "right" then
		sbar.exec("cliclick kd:fn t:n")
	end
end)
