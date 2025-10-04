local colors = require("colors")

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
	update_freq = 1,
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

-- Subscribe to routine + display change events
window_title:subscribe({ "routine", "display_change" }, update_window_title)

-- Initialize at startup
update_window_title()
