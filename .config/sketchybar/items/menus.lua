local colors = require("colors")
local settings = require("default")
local icons = require("icons")

local apple = sbar.add("item", {
	icon = {
		font = { size = 14 },
		string = icons.apple,
		position = "left",
		padding_left = 7,
		padding_right = 2,
		color = colors.white,
	},
	label = { drawing = false, width = 0 },
	padding_left = 0,
	padding_right = 0,
	y_offset = 0,
})

local menu_watcher = sbar.add("item", {
	drawing = false,
	updates = true,
})

sbar.add("event", "swap_menus_and_spaces")
local max_items = 15
local menu_items = {}
for i = 1, max_items, 1 do
	local menu = sbar.add("item", "menu." .. i, {
		padding_left = 2,
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
		click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s " .. i,
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

menu_watcher:subscribe(
	"window_focus",
	"front_app_switched",
	"space_change",
	"title_change",
	"display_change",
	"forced",
	"system_woke",
	update_menus
)

local theme_dir  = os.getenv("HOME") .. "/.config/sketchybar/themes/"
local theme_file = os.getenv("HOME") .. "/.config/sketchybar/current_theme"

-- Read theme names dynamically from theme_dir
local function list_themes()
  local themes = {}

  -- List *.lua files only
  local p = io.popen('ls -1 "' .. theme_dir .. '"')
  if not p then return themes end

  for file in p:lines() do
    -- strip .lua extension
    local name = file:match("^(.*)%.lua$")
    if name then
      table.insert(themes, name)
    end
  end
  p:close()

  table.sort(themes)  -- alphabetical order
  return themes
end

local function cycle_theme()
  local themes = list_themes()
  if #themes == 0 then
    return -- nothing to do
  end

  -- read current theme safely
  local f = io.open(theme_file, "r")
  local current = f and f:read("*l") or nil
  if f then f:close() end

  -- fallback to first theme if missing or empty
  if not current or current == "" then
    current = themes[1]
  end

  -- find current index
  local next_index = 1
  for i, t in ipairs(themes) do
    if t == current then
      next_index = (i % #themes) + 1
      break
    end
  end

  -- write next theme to the file
  local f2 = io.open(theme_file, "w")
  if f2 then
    f2:write(themes[next_index])
    f2:close()
  end
end

-- local menu_click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0"

for _, menu in ipairs(menu_items) do
	menu:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			return
		elseif env.BUTTON == "right" then
			sbar.exec("yabai -m config menubar_opacity 1.0")
		elseif env.BUTTON == "other" then
			cycle_theme()
			sbar.exec("sketchybar --reload")
		end
	end)
end

local left_click_script =
	"osascript -e 'tell application \"System Events\" to key code 46 using {command down, option down, control down}'"

local right_click_script =
	"osascript -e 'tell application \"System Events\" to key code 0 using {command down, option down, control down}'"

local middle_click_script = [[
osascript -e 'tell application "System Events"
    set thePic to do shell script "find ~/Pictures/Wallpapers -type f | gshuf -n 1"
    repeat with d in desktops
        set picture of d to thePic
    end repeat
end tell'
]]

apple:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(left_click_script)
	elseif env.BUTTON == "right" then
		sbar.exec(right_click_script)
	elseif env.BUTTON == "other" then
		sbar.exec(middle_click_script)
	end
end)

return menu_watcher
