local colors = require("colors")
local settings = require("default")
local app_icons = require("helpers.app_icons")

local front_app = sbar.add("item", "front_app", {
	display = "active",
	icon = {
		drawing = true,
		font = "sketchybar-app-font:Regular:15.0",
		string = "",
	},
	label = {
		drawing = false,
	},
	padding_right = 2,
	updates = true,
	position = "center",
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
			font = "sketchybar-app-font:Regular:15.0",
		},
		-- Set the app name as the label
		label = {
			string = app .. ": ",
			font = settings.default,
		},
	})
end)

-- Window title item
local window_title = sbar.add("item", "window_title", {
	position = "center",
	scroll_texts = false,
	icon = { drawing = false },
	label = {
		drawing = false,
		max_chars = 150,
		string = "",
		font = { family = settings.default, size = 12 },
		color = colors.white,
	},
})

local function get_front_window(callback)
	sbar.exec("yabai -m query --windows --window | jq -r '.title'", function(title)
		if title then
			title = title:gsub("\n", ""):gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
		end
		callback(title or "")
	end)
end

-- Cache previous title to avoid unnecessary updates
local last_title = ""

local function update_window_title()
	sbar.exec("system_profiler SPDisplaysDataType", function(result)
		if not result then
			return
		end

		local external_main = result:match("Sceptre")

		-- Show only if Sceptre external monitor exists (alone or with Built-In Macbook screen)
		if external_main then
			get_front_window(function(title)
				if title ~= last_title then
					last_title = title
					window_title:set({
						label = {
							string = title,
							drawing = title ~= "",
							updates = true,
						},
					})
				end
			end)
		else
			-- Hide if only Built-in is found
			window_title:set({ label = { drawing = false, string = "" } })
			last_title = ""
		end
	end)
end

-- Subscribe correctly (don’t call the function)
window_title:subscribe({
	"window_focus",
	"front_app_switched",
	"space_change",
	"title_change",
	"display_change",
}, update_window_title)

window_title:subscribe({
	"window_focus",
	"front_app_switched",
	"space_change",
	"title_change",
	"display_change",
}, update_window_title())

update_window_title()
