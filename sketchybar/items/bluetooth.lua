local colors = require("colors")
local icons = require("icons")
local settings = require("default")

local bluetooth = sbar.add("item", "bluetooth", {
	position = "right",
	padding_left = 4,
	padding_right = -5,
	update_freq = 10,
	icon = {
		string = icons.bluetooth.on,
		color = colors.white,
		font = { family = settings.default, size = 15 },
	},
	updates = "when_shown",
	click_script = 'osascript -e \'tell application "System Events" to tell process "ControlCenter" to click (first menu bar item of menu bar 1 whose name is not "Wi-Fi")\'',
})

-- Function to update Bluetooth icon
local function update_bluetooth()
	sbar.exec("/opt/homebrew/bin/blueutil --power", function(output)
		local state = tonumber(output)

		if state == 1 then
			bluetooth:set({
				icon = { string = icons.bluetooth.on },
			})
		else
			bluetooth:set({
				icon = { string = icons.bluetooth.off },
			})
		end
	end)
end

update_bluetooth()

-- ======== Hover effects ========
local function add_hover(item)
	item:subscribe("mouse.entered", function()
		item:set({
			background = {
				drawing = true,
				color = colors.hover,
				corner_radius = 20,
				height = 20,
				x_offset = 0,
			},
		})
	end)

	item:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
		item:set({ background = { drawing = false } })
	end)
end

add_hover(bluetooth)
