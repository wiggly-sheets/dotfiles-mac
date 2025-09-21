local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

local cal_up = sbar.add("item", "cal_up", {
	position = "right",
	padding_left = -10,
	padding_right = 42,
	width = 0,
	label = {
		color = colors.white,
		font = {
			family = settings.default,
			style = "Bold",
			size = 12,
		},
	},
	y_offset = 5,
	click_script = 'osascript -e \'tell application "System Events" to tell process "Dato" to click menu bar item 1 of menu bar 2\'',
})

local cal_down = sbar.add("item", "cal_down", {
	position = "right",
	padding_left = -10,
	padding_right = 0,
	y_offset = -5,
	label = {
		color = colors.white,
		font = {
			family = settings.default,
			style = "Bold",
			size = 12,
		},
	},
	click_script = 'osascript -e \'tell application "System Events" to tell process "Dato" to click menu bar item 1 of menu bar 2\'',
})

-- Double border for calendar using a single item bracket
local cal_bracket = sbar.add("bracket", { cal_up.name, cal_down.name }, {
	background = {
		color = colors.transparent,
		height = 30,
		border_color = colors.transparent,
	},
	update_freq = 1,
})

-- Padding item required because of bracket
local spacing = sbar.add("item", { position = "right", width = 26 })

cal_bracket:subscribe({ "forced", "routine", "system_woke" }, function(env)
	local down_value = os.date("%a %b %d %Y")
	local up_value = os.date("%H:%M:%S %Z")
	cal_up:set({ label = { string = up_value } })
	cal_down:set({ label = { string = down_value } })
end)
