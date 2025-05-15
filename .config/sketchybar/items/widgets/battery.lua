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

	--	popup = { align = "center" },
})

local battery_percentage = sbar.add("item", "widgets.battery_percentage", {
	position = "right",
	label = { font = { family = "IosevkaTermSlab Nerd Font Mono", size = 13 }, color = colors.green },
	click_script = 'osascript -e \'tell application "System Events" to tell process "AirBattery" to click menu bar item 1 of menu bar 2\'',
	padding_left = -10,
	padding_right = -10,
})

-- Single Instance Popup Items --
--local popup_items = {
--	time = sbar.add("item", {
--		position = "popup." .. battery.name,
--		icon = { string = "Time:", width = 100, align = "left" },
--		label = { string = "Calculating...", width = 100, align = "right" },
--	}),
--	capacity = sbar.add("item", {
--		position = "popup." .. battery.name,
--		icon = { string = "Capacity:", width = 100, align = "left" },
--		label = { string = "86%", width = 100, align = "right" },
--	}),
--	condition = sbar.add("item", {
--		position = "popup." .. battery.name,
--		icon = { string = "Condition:", width = 100, align = "left" },
--		label = { string = "Normal", width = 100, align = "right" },
--	}),
--	cycles = sbar.add("item", {
--		position = "popup." .. battery.name,
--		icon = { string = "Cycles:", width = 100, align = "left" },
--		label = { string = "Fetching...", width = 100, align = "right" },
--	}),
--}

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

-- Extract battery time remaining
--	local time_remaining = "Calculating..."
--	local time_match = batt_info:match("(%d+:%d+)")

--	if time_match then
--			time_remaining = charging and (time_match .. " until full") or (time_match .. " remaining")
--		end

-- Update time remaining in popup
--popup_items.time:set({ label = time_remaining })
--end)

---- Extract battery capacity
--sbar.exec("system_profiler SPPowerDataType | grep 'Maximum Capacity' | awk '{print $3}'", function(capacity)
--	local cap = capacity and capacity:match("%d+") or "N/A"
--	popup_items.capacity:set({ label = cap .. "%" })
--end)

---- Extract battery cycle count
--sbar.exec("system_profiler SPPowerDataType | grep 'Cycle Count' | awk '{print $3}'", function(cycles)
--	local cycle_count = cycles and cycles:match("%d+") or "N/A"
--	popup_items.cycles:set({ label = cycle_count })
--end)
--	end)

-- Popup Interactions --
--battery:subscribe("mouse.clicked", function()
--	local drawing = battery:query().popup.drawing
--	battery:set({ popup = { drawing = drawing == "off" and "on" or "off" } })
--end)
--
--battery:subscribe("mouse.exited.global", function()
--	battery:set({ popup = { drawing = "off" } })
--end)
--
--sbar.add("bracket", "widgets.battery.bracket", { battery.name }, {
--	background = { color = colors.bg1 },
--})
--
--sbar.add("item", "widgets.battery.padding", {
--	position = "right",
--	width = settings.group_paddings,
--	})
