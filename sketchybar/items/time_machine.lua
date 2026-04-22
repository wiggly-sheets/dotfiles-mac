local settings = require("default")
local colors = require("colors")
local icons = require("icons")

local time_machine = sbar.add("item", "time_machine", {
	position = "right",
	padding_left = 2,
	padding_right = -1,
	icon = { color = colors.white, font = { size = 13 }, string = icons.time_machine.default },
	click_script = 'osascript -e \'tell application "System Events" to tell process "SystemUIServer" to click (first menu bar item of menu bar 1 whose name is not "Siri")\'',
	update_freq = 10,
	label = { padding_right = 4 },
})

local function update_tm()
	-- Check if backup is running
	sbar.exec("tmutil status | grep Running", function(running_output)
		if running_output:match("1") then
			-- Backup currently running
			sbar.exec(
				"tmutil status | awk -F'= ' '/_raw_Percent|Percent/ && !/totalBytes/ {gsub(/[^0-9.]/,\"\",$2); sum+=$2; count++} END {printf \"%.0f\", (sum/count) * 100}'",
				function(percent)
					if tonumber(percent) >= 1 then
						time_machine:set({
							icon = { string = icons.time_machine.running },
							label = { string = percent .. "%" },
						})
					elseif tonumber(percent) <= 0 then
						time_machine:set({
							icon = { string = icons.time_machine.running },
							label = { string = "" },
						})
					else
						time_machine:set({
							icon = { string = icons.time_machine.default },
						})
					end
				end
			)
			return
		end
	end)
end

-- Run once on load
update_tm()

-- Poll (Time Machine is slow-moving anyway)
time_machine:set({
	update_freq = 60,
})

time_machine:subscribe("routine", function()
	update_tm()
end)

local function add_hover(item)
	item:subscribe("mouse.entered", function()
		item:set({
			background = {
				drawing = true,
				color = colors.hover,
				corner_radius = 20,
				height = 20,
				x_offset = -1,
			},
		})
	end)

	item:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
		item:set({ background = { drawing = false } })
	end)
end

add_hover(time_machine)
