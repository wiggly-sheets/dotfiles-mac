local settings = require("settings")
local colors = require("colors")

-- Click script example (optional, can toggle label/value)
local click_script =
	'osascript -e \'tell application "System Events" to keystroke "s" using {command down, option down, control down}\''

-- Add the disk item
local disk = sbar.add("item", "disk", {
	update_freq = 60, -- update every 60 seconds
	position = "right",
	padding_left = 0,
	y_offset = 0,
	icon = { string = "", padding_left = 2, padding_right = 2 }, -- default icon
	label = { padding_left = 1, padding_right = 0, font = { family = settings.default, size = 15 } },

	click_script = click_script, -- optional
})

-- Function to update disk usage
local function update_disk()
	sbar.exec("df /System/Volumes/Data | tail -1 | awk '{print $5}' | tr -d '%'", function(output)
		local usage = tonumber(output) or 0
		local icon = "󰪢"
		local color = colors.green

		if usage >= 98 then
			icon = "󰪥"
			color = colors.red
		elseif usage >= 88 then
			icon = "󰪤"
			color = colors.orange
		elseif usage >= 76 then
			icon = "󰪣"
			color = colors.orange
		elseif usage >= 64 then
			icon = "󰪢"
			color = colors.yellow
		elseif usage >= 52 then
			icon = "󰪡"
			color = colors.yellow
		elseif usage >= 40 then
			icon = "󰪠"
			color = colors.green
		elseif usage >= 28 then
			icon = "󰪟"
			color = colors.green
		elseif usage >= 16 then
			icon = "󰪞"
			color = colors.green
		else
			icon = "󰝦"
			color = colors.green
		end

		disk:set({
			icon = { string = icon, color = color, font = { size = 25 } },
			label = {
				string = usage .. "%",
				color = color,
				font = { family = settings.default, size = 12 },
			},
		})
	end)
end

-- Subscribe to routine updates
disk:subscribe({ "routine", "forced", "system_woke" }, update_disk)

-- Initial update
update_disk()
