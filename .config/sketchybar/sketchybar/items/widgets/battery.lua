local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Battery Widget --
local battery = sbar.add("item", "widgets.battery", {
	position = "right",
	icon = {
		font = { style = "IosevkaTermSlab Nerd Font Mono" },
		color = colors.green,
		padding_right = -1,
	},
	padding_left = 0,
	padding_right = -10,
	update_freq = 300,
	click_script = [[cliclick kd:cmd,alt,ctrl,shift t:-]],
})

local battery_percentage = sbar.add("item", "widgets.battery_percentage", {
	position = "right",
	label = { font = { family = "IosevkaTermSlab Nerd Font Mono", size = 13 }, color = colors.green },
	click_script = 'osascript -e \'tell application "System Events" to tell process "AirBattery" to click menu bar item 1 of menu bar 2\'',
	padding_left = -10,
	padding_right = -10,
})

-- Battery Updates --
battery:subscribe({ "routine", "power_source_change", "system_woke" }, function()
	sbar.exec("pmset -g batt", function(batt_info)
		local icon = "!"
		local label = "?"
		local color = colors.green
		local charging = batt_info:find("AC Power") and true or false

		local found, _, charge = batt_info:find("(%d+)%%")
		if found then
			charge = tonumber(charge)
			label = charge .. "%"
			-- Determine battery icon based on charge level
			icon = charge > 80 and icons.battery._100
				or charge > 60 and icons.battery._75
				or charge > 40 and icons.battery._50
				or charge > 20 and icons.battery._25
				or icons.battery._0

			-- Set color based on charge level
			color = charge > 20 and colors.green or charge > 10 and colors.orange or colors.red
		else
			-- Debug: If we didn’t find the charge value, output a warning
			print("Failed to parse battery charge")
		end

		-- Set battery widget state based on parsed data
		battery:set({
			icon = { string = charging and icons.battery.charging or icon, color = color },
		})
		battery_percentage:set({
			label = { string = label, color = color },
		})
	end)
end)
