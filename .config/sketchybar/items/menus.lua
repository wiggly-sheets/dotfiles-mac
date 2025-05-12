local colors = require("colors")
local icons = require("icons")
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
		padding_left = -4,
		padding_right = 1,
		drawing = false,
		icon = { drawing = true },
		label = {
			font = {
				style = settings.font.style_map[i == 1 and "Bold" or "Medium"],
				family = "IosevkaTermSlab Nerd Font Mono",
				size = 12,
			},
			padding_left = -3,
			padding_right = 5,
		},
		click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s " .. i,
	})

	menu_items[i] = menu
end

sbar.add("bracket", { "/menu\\..*/" }, {
	background = {
		color = colors.bg1,
		border_color = colors.white,
		border_width = 1,
		corner_radius = 10,
		height = 28,
	},
})

local menu_padding = sbar.add("item", "menu.padding", {
	drawing = false,
	width = 5,
	padding_left = -2,
	padding_right = -5,
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

menu_watcher:subscribe("front_app_switched", update_menus)
menu_watcher:subscribe("space_windows_change", update_menus)
return menu_watcher
