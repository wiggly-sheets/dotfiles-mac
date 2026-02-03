local icons = require("icons")
local colors = require("colors")
local settings = require("default")

-- ── Low Power Mode ────────────────────────────────────────────────
local lowpowermode = sbar.add("item", "lowpowermode", {
	update_freq = 10,
	position = "right",
	padding_right = -2,
	padding_left = -8,
	y_offset = -1,
	label = {
		font = { size = 10 },
		string = "􀋦",
	},
})
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
-- Left click toggles low power
lowpowermode:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec('shortcuts run "Toggle Low Power"')
		sbar.exec(update_lowpowermode())
	end
end)

lowpowermode:subscribe({ "power_source_change", "system_woke", "routine" }, update_lowpowermode)

update_lowpowermode()

-- ── Combined Battery Item ─────────────────────────────────────────
local battery_item = sbar.add("item", "battery", {
	position = "right",
	padding_left = 3,
	padding_right = 5,
	y_offset = 0,
	color = colors.green,
	icon = {
		drawing = true,
		string = icons.battery._100, -- initial icon
		font = { family = settings.default, size = 12 },
		color = colors.green,
	},
	label = {
		drawing = true,
		string = "__%", -- initial label
		padding_left = 2,
		padding_right = 2,
		font = { family = settings.default, size = 10 },
		color = colors.green,
	},
	update_freq = 30,
})

-- Click behavior for battery item
local function handle_battery_click(env)
	if env.BUTTON == "left" then
		sbar.exec(
			'osascript -e \'tell application "System Events" to keystroke "b" using {command down, option down, control down}\''
		)
	elseif env.BUTTON == "right" then
		sbar.exec(
			'osascript -e \'tell application "System Events" to tell process "AirBattery" to click menu bar item 1 of menu bar 2\''
		)
	else
		sbar.exec(
			'osascript -e \'tell application "System Events" to tell process "Battery Toolkit" to click menu bar item 1 of menu bar 2\''
		)
	end
end

battery_item:subscribe("mouse.clicked", handle_battery_click)

-- Update battery status
local function update_battery()
	sbar.exec("pmset -g batt", function(batt_info)
		local icon = icons.battery._0
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

		battery_item:set({
			icon = { string = charging and icons.battery.charging or icon, color = color },
			label = { string = label, color = color },
		})
	end)
end

battery_item:subscribe({ "routine", "power_source_change", "system_woke" }, update_battery)
update_battery()

-- Hover effects
local function add_hover(item)
	item:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
		item:set({ background = { drawing = false } })
	end)
end
add_hover(lowpowermode)
add_hover(battery_item)

battery_item:subscribe(
	"mouse.entered",
	function()
		battery_item:set({
			background = {
				drawing = true,
				color = 0x40FFFFFF,
				corner_radius = 20,
				height = 20,
				x_offset = 0,
			},
		})
	end,

	lowpowermode:subscribe("mouse.entered", function()
		lowpowermode:set({
			background = {
				drawing = true,
				color = 0x40FFFFFF,
				corner_radius = 20,
				height = 20,
				x_offset = 2,
			},
		})
	end)
)
