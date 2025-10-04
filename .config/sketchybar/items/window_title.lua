local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local front_app = sbar.add("item", "front_app", {
	display = "active",
	icon = {
		drawing = true,
		font = "sketchybar-app-font:16.0",
		string = "",
		padding_right = 0,
		padding_left = 0,
	},
	label = {
		drawing = false,
		font = {
			style = settings.font.style_map["Black"],
			size = 12.0,
		},
		string = "",
	},
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
			font = "sketchybar-app-font:16.0",
			padding_right = 5,
		},
		-- Set the app name as the label
		label = {
			string = app,
			font = "IosevkaTermSlab Nerd Font",
		},
	})
end)

-- Window title item
local window_title = sbar.add("item", "window_title", {
	position = "center",
	icon = { drawing = false },
	label = {
		drawing = false,
		string = "",
		font = { family = "Inconsolata Nerd Font Mono", size = 12 },
		color = colors.white,
	},
})

-- Cache previous title to avoid unnecessary updates
local last_title = ""

-- Check if an external display is connected
local function external_display_connected(callback)
	sbar.exec("system_profiler SPDisplaysDataType | grep -i 'Display' | grep -v 'Built-In'", function(result)
		callback(result and #result > 0)
	end)
end

-- Get frontmost window title
local function get_front_window(callback)
	sbar.exec("yabai -m query --windows --window | jq -r '.title'", function(title)
		if title then
			title = title:gsub("\n", ""):gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
		end
		callback(title or "")
	end)
end

-- Update function
local function update_window_title()
	external_display_connected(function(connected)
		if not connected then
			-- Hide if no external display
			window_title:set({ label = { drawing = false } })
			last_title = ""
			return
		end

		-- Only query window if display is connected
		get_front_window(function(title)
			-- Optional truncation
			local max_len = 500
			if #title > max_len then
				title = title:sub(1, max_len) .. "…"
			end

			-- Only update if title changed
			if title ~= last_title then
				last_title = title
				if title == "" then
					window_title:set({ label = { drawing = false } })
				else
					window_title:set({ label = { string = title, drawing = true } })
				end
			end
		end)
	end)
end

window_title:subscribe(
	{ "window_focus", "front_app_switched", "space_change", "title_change", "display_change" },
	update_window_title
)

-- Initialize at startup
update_window_title()
