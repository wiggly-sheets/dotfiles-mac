local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

local cal_up = sbar.add("item", "cal_up", {
	position = "right",
	padding_left = -3,
	padding_right = 21,
	width = 0,
	label = {
		color = colors.white,
		font = {
			family = "IosevkaTermSlab Nerd Font Mono",
			size = 11.0,
		},
	},
	y_offset = 5,
	click_script = "cliclick kd:fn t:n",
})

local cal_down = sbar.add("item", "cal_down", {
	position = "right",
	padding_left = -2,
	padding_right = 3,
	y_offset = -6,
	label = {
		color = colors.white,
		font = {
			family = "IosevkaTermSlab Nerd Font Mono",
			size = 11.0,
		},
	},
	click_script = "cliclick kd:fn t:n",
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
	local up_value = os.date("%a %b %d %Y")
	local down_value = os.date("%H:%M:%S %Z")
	cal_up:set({ label = { string = up_value } })
	cal_down:set({ label = { string = down_value } })
end)
