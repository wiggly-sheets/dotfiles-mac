local colors = require("colors")
local settings = require("settings")
local icons = require("icons")

local apple = sbar.add("item", {
	click_script = 'osascript -e \'tell application "System Events" to keystroke "a" using {command down, option down, control down}\'',
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
	y_offset = 1,
	--click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0",
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
		padding_left = 4,
		padding_right = 4,
		drawing = false,
		y_offset = 1,
		icon = { drawing = true },
		label = {
			font = {
				style = settings.font.style_map[i == 1 and "Bold" or "Medium"],
				family = settings.default,
				size = 12,
			},
		},
		--	click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s " .. i,
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
	update_menus
)

for _, menu in ipairs(menu_items) do
	menu:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			sbar.exec(
				"osascript -e 'tell application \"System Events\" to key code 46 using {command down, option down, control down}'"
			)
		elseif env.BUTTON == "right" then
			sbar.exec("yabai -m config menubar_opacity 1.0")
		end
	end)
end

apple:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(
			"osascript -e 'tell application \"System Events\" to key code 0 using {command down, option down, control down}'"
		)
	elseif env.BUTTON == "right" then
		sbar.exec("yabai -m config menubar_opacity 1.0")
	end
end)

return menu_watcher
