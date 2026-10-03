local colors = require("colors")
local icons = require("helpers.icons")
local settings = require("default")
local popup = require("helpers.popup")

local config_dir = os.getenv("HOME") .. "/.config/sketchybar/"

local apple = sbar.add("item", "apple", {
	position = "left",
	icon = {
		font = {size = 16}, -- 13 for command
		string = icons.apple,
		padding_left = 6,
		padding_right = 6,
		color = colors.white,
	},
	label = { drawing = false, width = 0 },
})

--------------------------THEME PICKER------------------------------

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

local function open_theme_popup()
	local rows = {}
	for i, theme in ipairs(theme_cache.themes) do
		rows[i] = {
			label = theme,
			active = theme == theme_cache.current,
			script = "echo '"
				.. theme
				.. "' > "
				.. theme_file
				.. " && sketchybar --reload"
				.. " && sketchybar --trigger theme_changed",
		}
	end
	popup.open(apple, { prefix = "theme.item", title = "Themes", rows = rows })
end

-- Keep the cache's "current" in sync after a theme switch
sbar.add("event", "theme_changed")
apple:subscribe("theme_changed", function()
	theme_cache.current = get_current_theme()
end)

--------------------------SETUP PICKER------------------------------

local setup_dir = config_dir .. "setups/"
local setup_file = setup_dir .. "current_setup"

local function get_current_setup()
	local f = io.open(setup_file, "r")
	if not f then
		return "default"
	end
	local name = f:read("*l")
	f:close()
	return name
end

local function list_setups()
	local setups = {}
	local p = io.popen('ls -1 "' .. setup_dir .. '"')
	if not p then
		return setups
	end
	for file in p:lines() do
		if not file:match("^%.") then
			local name = file:match("^(.*)%.lua$")
			if name then
				table.insert(setups, name)
			end
		end
	end
	p:close()

	table.sort(setups)
	return setups
end

local function open_setup_popup()
	local active = get_current_setup()
	local rows = {}
	for i, name in ipairs(list_setups()) do
		rows[i] = {
			label = name,
			active = name == active,
			script = "echo '"
				.. name
				.. "' > "
				.. setup_file
				.. " && sketchybar --reload",
		}
	end
	popup.open(apple, { prefix = "setup.item", title = "Setups", rows = rows })
end

apple:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		apple:set({ popup = { drawing = true } })
		open_theme_popup()
	elseif env.BUTTON == "right" then
		apple:set({ popup = { drawing = true } })
		open_setup_popup()
	end
end)

apple:subscribe("mouse.entered", function()
	apple:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 10,
			height = 20,
			x_offset = 1,
			y_offset = -1,
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
