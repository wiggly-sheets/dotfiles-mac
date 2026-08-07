local colors = require("colors")
local icons = require("helpers.icons")
local app_icons = require("helpers.icon_map")
local settings = require("default")

local spaces = {}
local space_separators = {}
local space_app_icons = {} -- sid -> concatenated icon glyphs (string)
local space_selected = {} -- sid -> bool
local space_selection_generation = 0

for i = 1, 10 do
	space_app_icons[i] = "—"
end

local function get_focused_space_index(callback)
	sbar.exec("yabai -m query --spaces --space | jq -r '.index'", function(output)
		callback(tonumber(output:match("(%d+)")))
	end)
end

local function update_space_display(space, space_id)
	sbar.exec("yabai -m query --spaces --space " .. space_id .. " | jq -r '.type'", function(output)
		local layout = output:gsub("%s+", "") -- bsp, float, stack
		local layout_letter = ""
		if layout == "bsp" then
			layout_letter = "b"
		elseif layout == "float" then
			layout_letter = "f"
		elseif layout == "stack" then
			layout_letter = "s"
		end

		local icon_text = space_app_icons[space_id] or "—"
		local space_text = tostring(space_id) .. layout_letter

		space:set({
			icon = {
				string = space_text,
			},
			label = {
				string = icon_text,
			},
		})
	end)
end

-- Show a visual break after the final space owned by each display. The spaces
-- themselves retain yabai's global indexes, so this stays correct as displays
-- are rearranged or spaces are moved between them.
local function refresh_space_separators()
	sbar.exec("yabai -m query --spaces | jq -r '.[] | \"\\(.index) \\(.display)\"'", function(output)
		local display_by_space = {}
		for space_id, display_id in output:gmatch("(%d+)%s+(%d+)") do
			display_by_space[tonumber(space_id)] = tonumber(display_id)
		end

		for space_id, separator in ipairs(space_separators) do
			local display_id = display_by_space[space_id]
			local next_display_id = display_by_space[space_id + 1]
			spaces[space_id]:set({ drawing = display_id ~= nil })
			separator:set({ drawing = display_id ~= nil and next_display_id ~= nil and display_id ~= next_display_id })
		end
	end)
end

for i = 1, 10 do
	local space = sbar.add("space", "space." .. i, {
		space = i,
		-- Keep every global space visible on the main bar; display grouping is
		-- represented by the separators below rather than SketchyBar hiding
		-- spaces that belong to a secondary display.
		ignore_association = true,
		icon = {
			font = { family = settings.default, size = 11, style = "Bold" },
			string = tostring(i),
			padding_left = 2,
			padding_right = 2,
			color = colors.grey,
			highlight_color = colors.white,
		},
		label = {
			padding_right = 2,
			padding_left = 2,
			color = colors.grey,
			highlight_color = colors.white,
			font = "sketchybar-app-font:Regular:11.0",
		},
		padding_right = 1,
		padding_left = 1,
	})
	spaces[i] = space

	local space_separator = sbar.add("item", "space_separator." .. i, {
		position = "left",
		drawing = false,
		width = 8,
		padding_left = 0,
		padding_right = 5,
		icon = {
			string = "│",
			font = { family = settings.default, size = 12, style = "Regular" },
			color = colors.grey,
		},
	})
	space_separators[i] = space_separator

	local space_bracket = sbar.add("bracket", { space.name }, {
		background = {
			height = 20,
			border_width = 1,
			padding_right = -5,
			padding_left = 5,
		},
	})

	local space_popup = sbar.add("item", {
		position = "popup." .. space.name,
		padding_left = 2,
		padding_right = 2,
		background = {
			border_color = colors.grey,
			border_width = 1,
			drawing = true,
			image = {
				corner_radius = 20,
				scale = 0.3,
			},
		},
	})

	space:subscribe("mouse.clicked", function(env)
		if env.BUTTON then
			local op = (env.BUTTON == "right") and "--destroy" or "--focus"
			sbar.exec("yabai -m space " .. op .. " " .. env.SID)
		end
	end)

	space:subscribe("mouse.entered", function()
		space:set({
			background = {
				drawing = true,
				color = colors.hover,
				corner_radius = 20,
				height = 20,
				x_offset = 0,
			},
		})
	end)

	space:subscribe("mouse.exited", function()
		space:set({ popup = { drawing = false }, background = { drawing = false } })
	end)

	space:subscribe("mouse.scrolled", function(env)
		space_popup:set({ background = { image = "space." .. env.SID } })
		space:set({ popup = { drawing = "toggle" } })
	end)
end

-- Space items associated with another display do not always receive the
-- selection event on a main-display bar. Ask yabai for its single focused
-- space, then update every visible item directly so the highlight follows
-- focus across displays.
local function refresh_space_selection()
	space_selection_generation = space_selection_generation + 1
	local generation = space_selection_generation

	get_focused_space_index(function(focused_space)
		-- A newer refresh was requested while yabai was responding. Ignore this
		-- stale result so it cannot restore the previous space's highlight.
		if generation ~= space_selection_generation then
			return
		end

		-- Apply the complete selection state as one SketchyBar transaction so
		-- there is never a frame where two spaces are highlighted.
		sbar.begin_config()
		for space_id, space in ipairs(spaces) do
			local is_selected = space_id == focused_space
			space_selected[space_id] = is_selected
			space:set({
				icon = { highlight = is_selected },
				label = { highlight = is_selected },
			})
		end
		sbar.end_config()

		-- Keep per-space content synchronized after the focused index shifts.
		for space_id, space in ipairs(spaces) do
			update_space_display(space, space_id)
		end
	end)
end

local space_display_observer = sbar.add("item", {
	drawing = false,
	updates = true,
})
space_display_observer:subscribe("space_change", function()
	refresh_space_separators()
	refresh_space_selection()
end)
space_display_observer:subscribe("display_change", function()
	refresh_space_separators()
	refresh_space_selection()
end)
refresh_space_separators()
refresh_space_selection()

-- Tracks the latest in-flight query per space so a slower/older yabai
-- response can never overwrite icons from a newer one (same pattern as
-- refresh_space_selection's generation guard above).
local space_icon_generation = {}

local space_window_observer = sbar.add("item", {
	drawing = false,
	updates = true,
})
space_window_observer:subscribe("space_windows_change", function(env)
	local sid = tonumber(env.INFO.space)
	if not sid then
		return
	end

	space_icon_generation[sid] = (space_icon_generation[sid] or 0) + 1
	local generation = space_icon_generation[sid]

	-- Sort by on-screen position (left-to-right, then top-to-bottom) so the
	-- icon order reflects actual window arrangement rather than app-name
	-- grouping. jq's sort_by is stable, so windows tied on position (e.g.
	-- stacked windows sharing a frame) fall back to yabai's own internal
	-- ordering, which tracks stack order.
	-- Exclude windows that shouldn't count toward a space's icon strip:
	--   - zero-size phantom windows (e.g. Gemini's off-screen helper)
	--   - non-standard roles/subroles (tooltips, hosting views, system
	--     dialogs, etc.) — real windows are AXWindow/AXStandardWindow
	--   - fully transparent windows (opacity == 0); note partially dimmed
	--     inactive windows (opacity ~0.8) are legitimate and kept
	--   - minimized windows
	--   - hidden windows (app hidden via Cmd+H)
	--   - sticky windows (already visible on every space, so redundant here)
	sbar.exec(
		"yabai -m query --windows --space "
			.. sid
			.. " | jq -r 'map(select("
			.. "(.frame.w > 0 and .frame.h > 0) "
			.. "and .role == \"AXWindow\" and .subrole == \"AXStandardWindow\" "
			.. "and .opacity > 0 "
			.. "and (.[\"is-minimized\"] == false) "
			.. "and (.[\"is-hidden\"] == false) "
			.. "and (.[\"is-sticky\"] == false)"
			.. ")) | sort_by(.frame.x, .frame.y) | .[].app'",
		function(output)
			if generation ~= space_icon_generation[sid] then
				return
			end

			local icon_line = ""
			for app in output:gmatch("[^\n]+") do
				local lookup = app_icons[app] or icons[app]
				local icon = lookup or app_icons["Default"]
				icon_line = icon_line .. icon
			end

			if icon_line == "" then
				icon_line = "—"
			end

			space_app_icons[sid] = icon_line

			-- Update displays for all spaces (use stored selected state)
			for space_id, space in ipairs(spaces) do
				update_space_display(space, space_id)
			end
		end
	)
end)

local add_space_button = sbar.add("item", "add_space_button", {
	position = "left",
	padding_right = 5,
	icon = { string = "+", font = { size = 15 }, color = colors.grey },
})

add_space_button:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec("yabai -m space --create")
	elseif env.BUTTON == "right" then
		sbar.exec("~/dotfiles/yabai/scripts/new_space_focus.sh")
	elseif env.BUTTON == "other" then
		sbar.exec("~/dotfiles/yabai/scripts/new_space_after.sh")
	end
end)

add_space_button:subscribe("mouse.entered", function()
	add_space_button:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 20,
			x_offset = -1,
		},
		icon = { color = colors.white },
	})
end)

add_space_button:subscribe("mouse.exited", "mouse.entered.global", "mouse.exited.global", function()
	add_space_button:set({
		background = {
			drawing = false,
		},
		icon = { color = colors.grey },
	})
end)