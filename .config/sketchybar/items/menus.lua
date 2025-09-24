local colors = require("colors")
local settings = require("settings")

local menu_watcher = sbar.add("item", {
	drawing = false,
	updates = true,
})
local space_menu_swap = sbar.add("item", {
	drawing = false,
	updates = true,
})
sbar.add("event", "swap_menus_and_spaces")
local max_items = 15
local menu_items = {}
for i = 1, max_items, 1 do
	local menu = sbar.add("item", "menu." .. i, {	
		padding_left = -6,
		padding_right = -6,
		drawing = false,
		y_offset = 1,
		icon = { drawing = true },
		label = {
			font = {
				style = settings.font.style_map[i == 1 and "Bold" or "Medium"],
				family = "Inconsolata Nerd Font Mono",
				size = 12,
			},
		},
		--	click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s " .. i,
	click_script = 'osascript -e \'tell application "System Events" to keystroke "m" using {command down, option down, control down}\'',
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
	width = 9,
	padding_left = 0,
	padding_right = 0,
})

local function update_menus(env)
	sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -l", function(menus)
		sbar.set("/menu\\..*/", { drawing = false})
		menu_padding:set({ drawing = true})
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

menu_watcher:subscribe("front_app_switched", update_menus)
menu_watcher:subscribe("space_windows_change", update_menus)
return menu_watcher
