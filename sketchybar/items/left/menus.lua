local colors = require("colors")
local settings = require("default")
local icons = require("helpers.icons")

local apple = sbar.add("item", "apple", {
	icon = {
		font = { size = 16 },
		string = icons.apple,
		position = "left",
		padding_left = 6,
		padding_right = 2,
		color = colors.white,
	},
	label = { drawing = false, width = 0 },
})

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

local menu_toggle = sbar.add("item", "menus.toggle", {
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

local menu_watcher = sbar.add("item", {
	drawing = false,
	updates = true,
})

local function toggle_menus()
	menus_expanded = not menus_expanded

	menu_toggle:set({
		icon = { string = menus_expanded and icons.menus.contract or icons.menus.expand },
	})

	for i = 2, #menu_items do
		menu_items[i]:set({ drawing = menus_expanded })
	end

	if menus_expanded then
		front_app:set({ icon = { drawing = false }, padding_left = -4 })
		update_menus()
	else
		front_app:set({
			icon = { drawing = true },
			padding_left = 2,
		})
	end
end

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

--------------------------THEME PICKER ------------------------------

local theme_dir = os.getenv("HOME") .. "/.config/sketchybar/themes/"
local theme_file = os.getenv("HOME") .. "/.config/sketchybar/themes/current_theme"

local function get_current_theme()
	local f = io.open(theme_file, "r")
	if not f then
		return nil
	end
	local t = f:read("*l")
	f:close()
	return t
end

local function list_themes()
	local themes = {}
	local p = io.popen('ls -1 "' .. theme_dir .. '"')
	if not p then
		return themes
	end
	for file in p:lines() do
		if not file:match("^%.") then
			local name = file:match("^(.*)%.lua$")
			if name then
				table.insert(themes, name)
			end
		end
	end
	p:close()

	table.sort(themes)
	return themes
end

-- Cache populated once at startup
local theme_cache = {
	current = get_current_theme(),
	themes = list_themes(),
}

local function clear_popup(prefix)
	sbar.remove("/" .. prefix .. "\\..*/")
	sbar.remove(prefix:match("^(.*)%.item$") .. ".header")
end

local theme_popup_subscribed = false

local function open_theme_popup(anchor)
	clear_popup("theme.item")

	sbar.add("item", "theme.header", {
		position = "popup." .. anchor.name,
		label = {
			string = "Themes",
			font = { family = settings.default, size = 11, style = "Bold" },
		},
		padding_left = 10,
		padding_right = 10,
	})

	-- Use cached data instead of hitting disk/shell here
	local current = theme_cache.current
	local themes = theme_cache.themes

	for i, theme in ipairs(themes) do
		local is_active = theme == current
		sbar.add("item", "theme.item." .. i, {
			position = "popup." .. anchor.name,
			label = theme,
			background = {
				drawing = is_active,
				color = is_active and colors.hover or colors.transparent,
				corner_radius = 20,
			},
			click_script = "echo '"
				.. theme
				.. "' > "
				.. theme_file
				.. " && sketchybar --reload"
				.. " && sketchybar --trigger theme_changed",
		})
	end

	if not theme_popup_subscribed then
		anchor:subscribe("mouse.exited.global", function()
			anchor:set({ popup = { drawing = false } })
			clear_popup("theme.item")
		end)
		theme_popup_subscribed = true
	end
end

-- Keep the cache's "current" in sync after a theme switch
sbar.add("event", "theme_changed")
sbar.subscribe("theme_changed", function()
	theme_cache.current = get_current_theme()
end)

-------------------Subscriptions--------------------------

local left_apple_script =
	"osascript -e 'tell application \"System Events\" to key code 46 using {command down, option down, control down}'"

local right_apple_script =
	"osascript -e 'tell application \"System Events\" to key code 0 using {command down, option down, control down}'"

-- Where you define the click handler for your anchor item:
apple:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(left_apple_script)
	elseif env.BUTTON == "right" then
		sbar.exec(right_apple_script)
	elseif env.BUTTON == "other" then
		apple:set({ popup = { drawing = not drawing } })
		if not drawing then
			open_theme_popup(apple)
		end
	end
end)

apple:subscribe("mouse.entered", function()
	apple:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 10,
			height = 20,
			x_offset = 3,
			width = 0,
		},
	})
end)

apple:subscribe("mouse.exited", function()
	apple:set({
		background = {
			drawing = false,
		},
	})
end)

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

menu_toggle:subscribe("mouse.scrolled.global", function()
	toggle_menus()
end)

return menu_watcher
