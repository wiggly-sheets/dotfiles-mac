local colors = require("colors")
local icons = require("helpers.icons")
local app_icons = require("helpers.icon_map")
local settings = require("default")

local spaces = {}
local space_app_icons = {} -- sid -> concatenated icon glyphs (string)
local space_selected = {} -- sid -> bool

for i = 1, 10 do
	space_app_icons[i] = "—"
end

local function update_space_display(space, space_id, is_selected)
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
				highlight = is_selected,
			},
			label = {
				string = icon_text,
				highlight = is_selected,
			},
		})
	end)
end

for i = 1, 10 do
	local space = sbar.add("space", "space." .. i, {
		space = i,
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

	space:subscribe("space_change", function(env)
		local sid = tonumber(env.SID) or i
		local is_selected = env.SELECTED == "true"

		update_space_display(space, sid, is_selected)
	end)

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

	for app, count in pairs(env.INFO.apps or {}) do
		no_app = false
		local lookup = app_icons[app] or icons[app]
		local icon = lookup or app_icons["Default"]
		icon_line = icon_line .. string.rep(icon, count)
	end

	if no_app then
		icon_line = "—"
	end

	space_app_icons[sid] = icon_line

	-- Update displays for all spaces (use stored selected state)
	for space_id, space in ipairs(spaces) do
		update_space_display(space, space_id, space_selected[space_id])
	end
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
		sbar.exec("~/dotfiles/yabai/scripts/new_space_close.sh")
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
