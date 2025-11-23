local icons = require("icons")
local colors = require("colors")
local settings = require("default")

-- ── Low Power Mode ────────────────────────────────────────────────
local lowpowermode = sbar.add("item", "lowpowermode", {
	update_freq = 5,
	position = "right",
	padding_right = 0,
	padding_left = -8,
	y_offset = -1,
	label = {
		font = { size = 10 },
		string = "􀋦",
	},
})

-- Left click toggles low power
lowpowermode:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec('shortcuts run "Toggle Low Power"')
	end
end)

-- Function to update low power mode color
local function update_lowpowermode()
	sbar.exec("pmset -g | grep lowpowermode | grep -o '[01]'", function(result)
		result = result:match("%d")
		if result == "1" then
			lowpowermode:set({ label = { color = colors.low_power } })
		else
			lowpowermode:set({ label = { color = colors.orange } })
		end
	end)
end

lowpowermode:subscribe({ "power_source_change", "system_woke", "routine" }, update_lowpowermode)
update_lowpowermode()

-- ── Battery Widgets ───────────────────────────────────────────────
local battery_percentage = sbar.add("item", "items.battery_percentage", {
	position = "right",
	padding_right = 3,
	padding_left = 10.5,
	y_offset = 6,
	label = { font = { family = settings.default, size = 9 }, color = colors.green },
	update_freq = 30,
})

local battery = sbar.add("item", "items.battery", {
	position = "right",
	padding_right = -35,
	padding_left = 6,
	y_offset = -5,
	icon = {
		font = { style = settings.default, size = 11 },
		color = colors.green,
	},
	update_freq = 30,
})

-- Shared click behavior for both battery items
local function handle_battery_click(env)
	if env.BUTTON == "left" then
		-- Left click: trigger keyboard shortcut
		sbar.exec(
			'osascript -e \'tell application "System Events" to keystroke "b" using {command down, option down, control down}\''
		)
	elseif env.BUTTON == "right" then
		-- Right click: open AirBattery menu
		sbar.exec(
			'osascript -e \'tell application "System Events" to tell process "AirBattery" to click menu bar item 1 of menu bar 2\''
		)
	end
end

battery:subscribe("mouse.clicked", handle_battery_click)
battery_percentage:subscribe("mouse.clicked", handle_battery_click)

-- Battery status updater
battery:subscribe({ "routine", "power_source_change", "system_woke" }, function()
	sbar.exec("pmset -g batt", function(batt_info)
		local icon = "!"
		local label = "?"
		local color = colors.green
		local charging = batt_info:find("AC Power") and true or false

		local _, _, charge = batt_info:find("(%d+)%%")
		if charge then
			charge = tonumber(charge)
			label = charge .. "%"
			icon = charge >= 80 and icons.battery._100
				or charge >= 60 and icons.battery._75
				or charge >= 40 and icons.battery._50
				or charge >= 20 and icons.battery._25
				or icons.battery._0

			color = charge >= 30 and colors.green or charge >= 20 and colors.orange or colors.red
		end

		battery:set({
			icon = { string = charging and icons.battery.charging or icon, color = color },
		})
		battery_percentage:set({
			label = { string = label, color = color },
		})
	end)
end)
