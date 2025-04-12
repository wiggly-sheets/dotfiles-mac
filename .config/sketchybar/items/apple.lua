local colors = require("colors")
local settings = require("settings")
local icons = require("icons")

-- Padding item required because of bracket
sbar.add("item", { width = 2 })

local apple = sbar.add("item", {
	icon = {
		font = { size = 15 },
		string = icons.apple,
		position = "left",
		padding_left = 5,
		padding_right = 5,
		color = colors.blue,
	},

	label = { drawing = false },
	background = {
		--		image = "/Users/Zeb/.config/sketchybar/proxy-image.png",
		width = 0,
		height = 10,
		color = colors.transparent,
		border_color = colors.transparent,
		border_width = 0,
	},
	padding_left = -15,
	padding_right = -3,
	--	click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0",
	click_script = "yabai -m config menubar_opacity 1.0",
})

-- Double border for apple using a single item bracket
sbar.add("bracket", { apple.name }, {
	background = {
		color = colors.transparent,
		height = 30,
		border_color = colors.transparent,
	},
})

-- Padding item required because of bracket
sbar.add("item", { width = 3 })
