local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local front_app = sbar.add("item", "front_app", {
	display = "active",
	-- Initialize the icon area (hidden until an app is active)
	icon = {
		drawing = false,
		font = "sketchybar-app-font:Regular:12.0", -- Ensure this is your icon font
		string = "",
		padding_right = 0,
		padding_left = 0,
		color = colors.white, -- Set icon color to magenta
	},
	-- click_script "osascript -e '(tell application "System Events" to set frontApp to name of first application process whose frontmost is true; tell process frontApp to click menu item 1 of menu (name of menu bar item 1 of menu bar 1) of menu bar 1)'"
	--	label = {
	--		font = {
	--			style = settings.font.style_map["Black"],
	--			size = 12.0,
	--		},
	--		background = {
	--			color = colors.magenta,
	--			border_width = 1,
	--			height = 26,
	--			border_color = colors.magenta,
	--			corner_radius = 20,
	--		},
	--		position = "left",
	--		string = "",
	--	},
	--	updates = true,
})

front_app:subscribe("front_app_switched", function(env)
	-- env.INFO is assumed to be the app name (e.g., "Safari")
	local app = env.INFO
	-- Look up the icon for the app; fall back to "Default" if none is found.
	local icon = app_icons[app] or app_icons["Default"]

	front_app:set({
		-- Enable icon drawing and set the proper icon font, string, and color
		icon = {
			drawing = true,
			string = icon,
			font = "sketchybar-app-font:Regular:13.0", -- Must be an icon-supporting font
			padding_right = -12,
			color = colors.white, -- Set icon color to magenta
		},
		-- Set the app name as the label
		--		label = {
		--			string = app,
		--			font = "IosevkaTermSlab Nerd Font",
		--		},
	})
end)

-- front_app:subscribe("mouse.clicked", function(env)
--  #	sbar.trigger("swap_menus_and_spaces")
-- end)
