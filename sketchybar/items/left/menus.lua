local colors = require("colors")
local settings = require("default")
local icons = require("helpers.icons")



local menus_expanded = false

local max_items = 15

local menu_items = {}
for i = 1, max_items, 1 do
	local menu = sbar.add("item", "menu." .. i, {
		padding_left = 0,
		padding_right = 2,
		drawing = i == 1,
		label = {
			color = colors.white,
			font = {
				style = i == 1 and "Bold" or "Medium",
				family = settings.default,
				size = 10,
			},
		},
	})

	menu_items[i] = menu
end

local front_app = sbar.add("item", "front_app", {
	position = "left",
	updates = true,
	icon = {
		background = {
			drawing = true,
			image = { scale = 0.6 },
		},
	},
})

front_app:subscribe("front_app_switched", function(env)
	local app = env.INFO

	front_app:set({
		icon = {
			background = {
				image = "app." .. env.INFO,
			},
		},
	})
end)

local window_title = sbar.add("item", "window_title", {
	position = "left",
	scroll_texts = false,
	updates = true,
	icon = { drawing = false },
	label = {
		drawing = false,
		string = "",
		font = { family = settings.default, size = 10, style = "Medium" },
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

local function get_visible_space_count(callback)
	sbar.exec("yabai -m query --spaces | jq 'length'", function(output)
		callback(tonumber(output:match("(%d+)")) or 10)
	end)
end

-- Cache previous title to avoid unnecessary updates
local last_title = ""

local function update_window_title()
	get_front_window(function(title)
		get_visible_space_count(function(space_count)
			-- Ten spaces retains the old 40-character cap. Each absent space
			-- frees three characters, up to 67 for a single-space layout.
			local max_len = math.max(20, 70 - (space_count * 3))
			if #title > max_len then
				title = title:sub(1, max_len - 3) .. "..."
			end
			if title ~= last_title then
				last_title = title
				window_title:set({
					label = {
						string = title,
						drawing = (not menus_expanded) and title ~= "",
					},
				})
			else
				window_title:set({
					label = {
						drawing = not menus_expanded and title ~= "",
					},
				})
			end
		end)
	end)
end

-- Initial blank state, set once before the first real update
window_title:set({ label = { drawing = false, string = "" } })
last_title = ""

window_title:subscribe({
	"window_focus",
    "title_change",
	"front_app_switched",
	"space_change"
}, update_window_title)

update_window_title()

local menu_toggle = sbar.add("item", "menus.toggle", {
	drawing = false,
	icon = {
		string = icons.menus.expand,
		font = { family = settings.default, size = 12 },
		color = colors.white,
	},
	label = { drawing = false },
	padding_left = 2,
	padding_right = 2,
	position = "left",
})

local function update_menus(env)
	sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -l", function(menus)
		sbar.set("/menu\\..*/", { drawing = false })
		id = 1
		for menu in string.gmatch(menus, "[^\r\n]+") do
			if id < max_items then
				menu_items[id]:set({
					label = menu,
					drawing = (id == 1) or menus_expanded,
				})
			else
				break
			end
			id = id + 1
		end

		-- hide any remaining preallocated menu items
		for i = id, max_items do
			menu_items[i]:set({ drawing = false })
		end
	end)
end

-- The menu row takes the same left-hand space as the Space indicators while
-- it is expanded. Keep this here so the two presentation modes stay coupled.
local function set_spaces_visible(visible)
	if not visible then
		for space_id = 1, 10 do
			sbar.set("space." .. space_id, { drawing = false })
			sbar.set("space_separator." .. space_id, { drawing = false })
		end
	end
	sbar.set("add_space_button", { drawing = visible })
	sbar.exec("sketchybar --trigger space_visibility_changed INFO=" .. (visible and "shown" or "hidden"))
end

local menu_watcher = sbar.add("item", {
	drawing = false,
	updates = true,
})

local function apply_menu_presentation()
	menu_toggle:set({
		drawing = menus_expanded,
		icon = { string = menus_expanded and icons.menus.contract or icons.menus.expand },
	})

	for i = 2, #menu_items do
		menu_items[i]:set({ drawing = menus_expanded })
	end

	if menus_expanded then
		-- Keep the app icon as an anchor for the aliased native menus.
		sbar.exec("sketchybar --move front_app after menu.1")
		front_app:set({ icon = { drawing = true }, padding_left = 2 })
		window_title:set({ label = { drawing = false } })
		set_spaces_visible(false)
		update_menus()
	else
		sbar.exec("sketchybar --move front_app after menu.1")
		front_app:set({
			icon = { drawing = true },
            padding_left = 2,
        })
		set_spaces_visible(true)
		update_window_title()
	end
end

local function toggle_menus()
	menus_expanded = not menus_expanded
	apply_menu_presentation()
end

-- The title is the primary control in the normal layout. The compact toggle
-- remains visible with the native menus as the obvious way back.
window_title:subscribe("mouse.clicked", function()
	toggle_menus()
end)

menu_toggle:subscribe("mouse.clicked", function()
	toggle_menus()
end)

menu_watcher:subscribe("front_app_switched", "window_focus", update_menus)

for i, menu in ipairs(menu_items) do
	menu:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			-- run menu action
			sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -s " .. i)

			menu:set({
				background = {
					drawing = true,
					color = colors.hover,
					corner_radius = 20,
					height = 20,
					x_offset = 1,
					y_offset = -1,
				},
			})

			-- un-highlight all others
			for _, other in ipairs(menu_items) do
				if other ~= menu then
					other:set({
						background = {
							drawing = false,
						},
					})
				end
			end
		end
	end)
end

local clear_highlights = function()
	for _, menu in ipairs(menu_items) do
		menu:set({
			background = { drawing = false },
		})
	end
end

for i, menu in ipairs(menu_items) do
	menu:subscribe("mouse.exited", function()
		clear_highlights()
	end)
end

for i, menu in ipairs(menu_items) do
	menu:subscribe("mouse.entered", function(env)
		menu:set({
			background = {
				drawing = true,
				color = colors.hover,
				corner_radius = 20,
				height = 20,
				x_offset = 1,
				y_offset = -1,
			},
		})
	end)
end



local left_front_app_script = 'osascript -e \'tell application "System Events" to keystroke "w" using {command down}\''

local right_front_app_script =
	"osascript -e 'tell application \"System Events\" to set frontApp to name of first application process whose frontmost is true' -e 'tell application frontApp to quit'"

local middle_front_app_script =
	'osascript -e \'tell application "System Events" to keystroke "h" using {command down}\''

front_app:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(left_front_app_script)
	elseif env.BUTTON == "right" then
		sbar.exec(right_front_app_script)
	else
		sbar.exec(middle_front_app_script)
	end
end)

front_app:subscribe("mouse.entered", function()
	front_app:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 10,
			height = 20,
			x_offset = -1,
		},
	})
end)

front_app:subscribe("mouse.exited", function()
	front_app:set({
		background = {
			drawing = false,
		},
	})
end)

menu_toggle:subscribe("mouse.exited", function()
	menu_toggle:set({
		background = {
			drawing = false,
		},
	})
end)

menu_toggle:subscribe("mouse.entered", function()
	menu_toggle:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 10,
			height = 20,
			x_offset = 1,
		},
	})
end)

window_title:subscribe("mouse.exited", function()
	window_title:set({ background = { drawing = false } })
end)

window_title:subscribe("mouse.entered", function()
	window_title:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 10,
			height = 20,
		},
	})
end)

menu_toggle:subscribe("mouse.scrolled.global", function()
	toggle_menus()
end)

return menu_watcher
