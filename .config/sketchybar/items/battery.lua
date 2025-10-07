local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local lowpowermode = sbar.add("item", "lowpowermode", {
	update_freq = 2,
	position = "right",
	padding_right = -10,
	padding_left = 2,
	y_offset = -1,
	label = {
		font = { size = 10 },
		string = "􀋦",
	},
})

lowpowermode:subscribe("mouse.clicked", function(env)
	sbar.exec('shortcuts run "Toggle Low Power"')
end)
-- Function to update low power mode color
local function update_lowpowermode()
	sbar.exec("pmset -g | grep lowpowermode | grep -o '[01]'", function(result)
		result = result:match("%d") -- extract 0 or 1
		if result == "1" then
			lowpowermode:set({ label = { color = colors.green } }) -- green
		else
			lowpowermode:set({ label = { color = colors.orange } }) -- orange
		end
	end)
end

-- Subscribe to battery/power events
lowpowermode:subscribe({ "power_source_change", "system_woke", "routine" }, update_lowpowermode)

update_lowpowermode()

local battery_percentage = sbar.add("item", "items.battery_percentage", {
	position = "right",
	padding_right = 0,
	padding_left = 4,
	label = { font = { family = settings.default, size = 12 }, color = colors.green },
	click_script = 'osascript -e \'tell application "System Events" to tell process "AirBattery" to click menu bar item 1 of menu bar 2\'',
	update_freq = 60,
})

local battery = sbar.add("item", "items.battery", {
	position = "right",
	padding_right = -3,
	padding_left = 2,

	icon = {
		font = { style = settings.default },
		color = colors.green,
	},
	update_freq = 60,
	click_script = 'osascript -e \'tell application "System Events" to keystroke "b" using {command down, option down, control down}\'',
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
			icon = charge >= 90 and icons.battery._100
				or charge >= 70 and icons.battery._75
				or charge >= 40 and icons.battery._50
				or charge >= 20 and icons.battery._25
				or icons.battery._0

			-- Set color based on charge level
			color = charge >= 30 and colors.green or charge >= 20 and colors.orange or colors.red
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
