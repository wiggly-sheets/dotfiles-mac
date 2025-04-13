local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}
local space_app_icons = {}

for i = 1, 10 do
	space_app_icons[i] = "—"
end

-- Function to update space icon with number + layout, and label with icons
local function update_space_display(space, space_id, is_selected)
	sbar.exec("yabai -m query --spaces --space " .. space_id .. " | jq -r '.type'", function(output)
		local layout_map = { stack = "s", float = "f", bsp = "b" }
		local layout = layout_map[output:gsub("\n", "")] or "?"
		local icon_text = space_app_icons[space_id] -- App icons inside space
		local space_text = tostring(space_id) .. "(" .. layout .. ")" -- e.g., "1(bsp)"

		space:set({
			icon = { string = space_text, highlight = is_selected }, -- ✅ Layout inside icon
			label = { string = icon_text, highlight = is_selected }, -- ✅ App icons in label
			background = { border_color = is_selected and colors.transparent or colors.transparent },
		})
	end)
end

for i = 1, 10, 1 do
	local space = sbar.add("space", "space." .. i, {
		space = i,
		icon = {
			font = { family = "IosevkaTermSlab Nerd Font Mono", size = 13, style = "Medium" },
			string = tostring(i), -- Placeholder before update
			padding_left = 3,
			padding_right = 1,
			color = colors.white,
			highlight_color = colors.white,
		},
		label = {
			padding_right = 2,
			padding_left = 2,
			color = colors.white,
			highlight_color = colors.white,
			font = "sketchybar-app-font:Regular:12.0",
			y_offset = -1,
		},
		padding_right = 0,
		padding_left = 2,
		background = {
			color = colors.transparent,
			border_width = 1,
			height = 26,
			border_color = colors.transparent,
		},
		popup = { background = { border_width = 3, border_color = colors.transparent } },
	})
	spaces[i] = space

	local space_bracket = sbar.add("bracket", { space.name }, {
		background = {
			color = colors.transparent,
			border_color = colors.transparent,
			height = 28,
			border_width = 1,
			padding_right = -5,
		},
	})

	sbar.add("space", "space.padding." .. i, {
		space = i,
		script = "",
		width = 0,
		padding_left = 2,
		padding_right = -2,
	})

	local space_popup = sbar.add("item", {
		position = "popup." .. space.name,
		padding_left = 0,
		padding_right = 0,
		background = {
			drawing = true,
			image = {
				corner_radius = 10,
				scale = 0.2,
			},
		},
	})

	-- Update space on change
	space:subscribe("space_change", function(env)
		local is_selected = env.SELECTED == "true"
		update_space_display(space, env.SID, is_selected)

		space_bracket:set({
			background = {
				border_color = is_selected and colors.green or colors.transparent,
				corner_radius = 10,
			},
		})
	end)

	space:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "other" then
			space_popup:set({ background = { image = "space." .. env.SID } })
			space:set({ popup = { drawing = "toggle" } })
		else
			local op = (env.BUTTON == "right") and "--destroy" or "--focus"
			sbar.exec("yabai -m space " .. op .. " " .. env.SID)
		end
	end)

	space:subscribe("mouse.exited", function(_)
		space:set({ popup = { drawing = false } })
	end)
end

local space_window_observer = sbar.add("item", {
	drawing = false,
	updates = true,
})

-- Track window changes and update space labels with icons
space_window_observer:subscribe("space_windows_change", function(env)
	local sid = env.INFO.space
	local icon_line = ""
	local no_app = true

	for app, count in pairs(env.INFO.apps) do
		no_app = false
		local lookup = app_icons[app] or icons[app]
		local icon = lookup or app_icons["Default"] -- Use default if no match
		icon_line = icon_line .. icon
	end

	if no_app then
		icon_line = "—"
	end

	space_app_icons[sid] = icon_line

	for space_id, space in ipairs(spaces) do
		local is_selected = (space_id == sid)
		update_space_display(space, space_id, is_selected)
	end
end)
