local colors = require("colors")
local settings = require("default")
local icons = require("icons")

local apple = sbar.add("item", {
	icon = {
		font = { size = 14 },
		string = icons.apple,
		position = "left",
		padding_left = 5,
		padding_right = 2,
		color = colors.white,
	},
	label = { drawing = false, width = 0 },
	padding_left = 0,
	padding_right = 0,
})

local menu_watcher = sbar.add("item", {
	drawing = false,
	updates = true,
})

local max_items = 15
local menu_items = {}
for i = 1, max_items, 1 do
	local menu = sbar.add("item", "menu." .. i, {
		padding_left = 0,
		padding_right = 2,
		drawing = false,
		y_offset = 0,
		icon = { drawing = true },
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

sbar.add("bracket", { "/menu\\..*/" }, {
	background = {
		color = colors.bg1,
		border_color = colors.transparent,
		height = 20,
	},
	width = 50,
})

local menu_padding = sbar.add("item", "menu.padding", {
	drawing = true,
	width = 5,
	padding_left = 0,
	padding_right = 0,
})

local function update_menus(env)
	sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -l", function(menus)
		sbar.set("/menu\\..*/", { drawing = false })
		menu_padding:set({ drawing = true })
		id = 1
		for menu in string.gmatch(menus, "[^\r\n]+") do
			if id < max_items then
				menu_items[id]:set({ label = menu, drawing = true })
			else
				break
			end
			id = id + 1
		end
	end)
end

menu_watcher:subscribe("front_app_switched", "display_change", "forced", "system_woke", update_menus)

local theme_dir = os.getenv("HOME") .. "/.config/sketchybar/themes/"
local theme_file = os.getenv("HOME") .. "/.config/sketchybar/current_theme"

local function get_current_theme()
	local f = io.open(theme_file, "r")
	if not f then
		return nil
	end
	local t = f:read("*l")
	f:close()
	return t
end

-- Read theme names dynamically from theme_dir
local function list_themes()
	local themes = {}

	-- List *.lua files only
	local p = io.popen('ls -1 "' .. theme_dir .. '"')
	if not p then
		return themes
	end

	for file in p:lines() do
		-- strip .lua extension
		local name = file:match("^(.*)%.lua$")
		if name then
			table.insert(themes, name)
		end
	end
	p:close()

	table.sort(themes) -- alphabetical order
	return themes
end

local wallpaper_cache = {
	list = nil,
	last_scan = 0,
	ttl = 10, -- seconds
}

local function list_wallpapers()
	local now = os.time()

	-- return cached results if still fresh
	if wallpaper_cache.list and (now - wallpaper_cache.last_scan) < wallpaper_cache.ttl then
		return wallpaper_cache.list
	end

	local wallpapers = {}
	local p = io.popen('find "$HOME/Pictures/Wallpapers" -type f')
	if not p then
		return wallpapers
	end

	for file in p:lines() do
		table.insert(wallpapers, file)
	end
	p:close()

	table.sort(wallpapers)

	wallpaper_cache.list = wallpapers
	wallpaper_cache.last_scan = now

	return wallpapers
end

local function clear_popup(prefix)
	sbar.remove("/" .. prefix .. "\\..*/")
	sbar.remove("/.*\\.header/")
end

local function open_theme_popup(anchor)
	clear_popup("theme.item")
	clear_popup("wallpaper.item")

	-- Header
	sbar.add("item", "theme.header", {
		position = "popup." .. anchor.name,
		label = {
			string = "Themes",
			font = { family = settings.default, size = 11, style = "Bold" },
		},
		padding_left = 10,
		padding_right = 10,
	})

	local current = get_current_theme()
	local themes = list_themes()

	for i, theme in ipairs(themes) do
		local is_active = theme == current
		sbar.add("item", "theme.item." .. i, {
			position = "popup." .. anchor.name,
			label = theme,
			background = {
				drawing = is_active,
				color = is_active and 0x40FFFFFF or colors.transparent,
				corner_radius = 6,
			},
			click_script = "echo '" .. theme .. "' > " .. theme_file .. " && sketchybar --reload",
		})
	end

	anchor:set({ popup = { drawing = "toggle" } })
end

local function open_wallpaper_popup(anchor)
	clear_popup("wallpaper.item")
	clear_popup("theme.item")

	-- Header
	sbar.add("item", "wallpaper.header", {
		position = "popup." .. anchor.name,
		label = {
			string = "Wallpapers",
			font = { family = settings.default, size = 11, style = "Bold" },
		},
		padding_left = 10,
		padding_right = 10,
	})

	local wallpapers = list_wallpapers()

	for i, wp in ipairs(wallpapers) do
		sbar.add("item", "wallpaper.item." .. i, {
			position = "popup." .. anchor.name,
			label = wp:match("([^/]+)$"),
			click_script = 'osascript -e \'tell application "System Events" to set picture of every desktop to "'
				.. wp
				.. "\"'",
		})
	end

	anchor:set({ popup = { drawing = "toggle", height = 25 } })
end

for i, menu in ipairs(menu_items) do
	menu:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			-- run menu action
			sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -s " .. i)

			-- highlight this item
			menu:set({
				background = {
					drawing = true,
					color = 0x40FFFFFF,
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
		elseif env.BUTTON == "right" then
			open_wallpaper_popup(menu)
		elseif env.BUTTON == "other" then
			open_theme_popup(menu)
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
				color = 0x40FFFFFF,
				corner_radius = 20,
				height = 20,
				x_offset = 1,
				y_offset = -1,
			},
		})
	end)
end

local left_apple_script =
	"osascript -e 'tell application \"System Events\" to key code 46 using {command down, option down, control down}'"

local right_apple_script =
	"osascript -e 'tell application \"System Events\" to key code 0 using {command down, option down, control down}'"

apple:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		-- highlight this item
		apple:set({
			background = {
				drawing = true,
				color = 0x40FFFFFF,
				corner_radius = 20,
				height = 20,
				x_offset = 1,
			},
		})
		sbar.exec(left_apple_script)
	elseif env.BUTTON == "right" then
		apple:set({
			background = {
				drawing = true,
				color = 0x40FFFFFF,
				corner_radius = 20,
				height = 20,
				x_offset = 1,
			},
		})
		sbar.exec(right_apple_script)
	end
end)

apple:subscribe("mouse.exited", function()
	apple:set({
		background = {
			drawing = false,
		},
	})
end)

apple:subscribe("mouse.entered", function()
	apple:set({
		background = {
			drawing = true,
			color = 0x40FFFFFF,
			corner_radius = 10,
			height = 20,
			x_offset = 1,
			width = 0,
		},
	})
end)

return menu_watcher
