local colors = require("colors")
local settings = require("default")

local window_title = sbar.add("item", "window_title", {
	position = "left",
	scroll_texts = false,
	updates = true,
	icon = { drawing = false },
	label = {
		drawing = false,
		string = "",
		font = { family = settings.default, size = 11, style = "regular" },
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
	get_front_window(function(title)
		-- Simple end truncation (ACTIVE)
		local max_len = 120
		if #title > max_len then
			title = title:sub(1, max_len - 3) .. "..."
		end

		--[[
		-- Middle truncation (OPTIONAL – uncomment to use instead)
		local max_len = 120
		if #title > max_len then
			local ellipsis = "..."
			local keep = max_len - #ellipsis
			local front_len = math.floor(keep / 2)
			local back_len = keep - front_len
			local front = title:sub(1, front_len)
			local back = title:sub(-back_len)
			title = front .. ellipsis .. back
		end
		]]

		if title ~= last_title then
			last_title = title
			window_title:set({
				label = {
					string = title,
					drawing = title ~= "",
				},
			})
		end
	end)
end

-- Initial blank state, set once before the first real update
window_title:set({ label = { drawing = false, string = "" } })
last_title = ""

window_title:subscribe({
	"window_focus",
	"title_change",
}, update_window_title)

update_window_title()