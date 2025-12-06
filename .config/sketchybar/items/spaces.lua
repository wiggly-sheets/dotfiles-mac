local colors = require("colors")
local icons = require("icons")
local app_icons = require("helpers.app_icons")
local settings = require("default")



local divider = sbar.add("item", "divider", {
	icon = {
		font = { family = settings.default, size = 12 },
		string = "│",
		drawing = true,
		color = colors.white,
	},
	padding_left = -2,
	padding_right = 4,
	position = "left",
})


local spaces = {}
local space_app_icons = {} -- sid -> concatenated icon glyphs (string)
local space_app_names = {} -- sid -> set/table of app names present in that space
local space_contains_front_app = {} -- sid -> bool
local space_selected = {} -- sid -> bool
local current_front_app = nil

-- init tables
for i = 1, 10 do
	space_app_icons[i] = "—"
	space_app_names[i] = {}
	space_contains_front_app[i] = false
	space_selected[i] = false
end

-- Helper: update how a space looks
local function update_space_display(space, space_id, is_selected, has_front_app)
	local icon_text = space_app_icons[space_id] or "—"
	local space_text = tostring(space_id)

	-- Space number / highlight: white if selected, otherwise grey
	local icon_color = is_selected and colors.white or colors.grey
	-- App icons string: white if that space contains the front app, otherwise grey
	local label_color = has_front_app and colors.white or colors.grey

	space:set({
		icon = {
			string = space_text,
			highlight = is_selected,
			color = icon_color,
		},
		label = {
			string = icon_text,
			highlight = is_selected,
			color = label_color,
		},
	})
end

-- Build spaces
for i = 1, 10 do
	local space = sbar.add("space", "space." .. i, {
		space = i,
		icon = {
			font = { family = settings.default, size = 11, style = "Medium" },
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
		padding_right = 0,
		padding_left = 0,
	})
	spaces[i] = space

	local space_bracket = sbar.add("bracket", { space.name }, {
		background = {
			color = colors.transparent,
			border_color = colors.transparent,
			height = 20,
			border_width = 1,
			padding_right = -5,
			padding_left = 5,
		},
	})

	sbar.add("space", "space.padding." .. i, {
		space = i,
		script = "",
		width = 2,
		padding_left = 5,
		padding_right = 5,
	})

	local space_popup = sbar.add("item", {
		position = "popup." .. space.name,
		padding_left = 2,
		padding_right = 2,
		background = {
			border_color = colors.dnd,
			border_width = 1,
			drawing = true,
			image = {
				corner_radius = 8,
				scale = 0.3,
			},
		},
	})

	-- When the space selection changes, update selected state & visuals
	space:subscribe("space_change", function(env)
		local sid = tonumber(env.SID) or i
		local is_selected = env.SELECTED == "true"
		space_selected[sid] = is_selected

		-- update bracket border
		space_bracket:set({
			background = {
				drawing = false,
			},
		})

		-- update that space's display (label color depends on whether it contains the front app)
		update_space_display(space, sid, is_selected, space_contains_front_app[sid])
	end)

	-- Click handling
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

-- Listen for front app changes
local front_app_listener = sbar.add("item", { drawing = false })
front_app_listener:subscribe("front_app_switched", function(env)
	current_front_app = env.INFO -- e.g. "Safari"

	-- Re-evaluate which spaces contain that front app based on last-known space_app_names
	for sid = 1, #space_app_names do
		local appset = space_app_names[sid] or {}
		local has = false
		if current_front_app and appset[current_front_app] then
			has = true
		end
		space_contains_front_app[sid] = has
	end

	-- Update visuals for all spaces
	for sid, space in ipairs(spaces) do
		update_space_display(space, sid, space_selected[sid], space_contains_front_app[sid])
	end
end)

-- Track window changes and update space labels + app sets
local space_window_observer = sbar.add("item", {
	drawing = false,
	updates = true,
})
space_window_observer:subscribe("space_windows_change", function(env)
	local sid = tonumber(env.INFO.space)
	if not sid then
		return
	end

	local icon_line = ""
	local no_app = true
	local appset = {}

	-- build icon string and app set
	for app, count in pairs(env.INFO.apps or {}) do
		no_app = false
		local lookup = app_icons[app] or icons[app]
		local icon = lookup or app_icons["Default"]
		icon_line = icon_line .. string.rep(icon, count)
		appset[app] = true
	end

	if no_app then
		icon_line = "—"
	end

	space_app_icons[sid] = icon_line
	space_app_names[sid] = appset

	-- Update whether this space contains the current front app (if known)
	space_contains_front_app[sid] = (current_front_app and appset[current_front_app]) and true or false

	-- Update displays for all spaces (use stored selected state)
	for space_id, space in ipairs(spaces) do
		update_space_display(space, space_id, space_selected[space_id], space_contains_front_app[space_id])
	end
end)


local divider2 = sbar.add("item", "divider2", {
	icon = {
		font = { family = settings.default, size = 12 },
		string = "│",
		drawing = true,
		color = colors.white
	},
	padding_left = -2,
	padding_right = 0,
	position = "left",
})