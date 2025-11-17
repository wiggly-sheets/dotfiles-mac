local settings = require("settings")
local colors = require("colors")

local click_script =
	'osascript -e \'tell application "System Events" to keystroke "s" using {command down, option down, control down}\''

-- Disk icon item
local disk_icon = sbar.add("item", "disk_icon", {
	update_freq = 60,
	position = "right",
	padding_left = -36,
	padding_right = 20,
	y_offset = 8,
	icon = { font = { size = 14 } },
	click_script = click_script,
})

-- Disk label item
local disk_label = sbar.add("item", "disk_label", {
	update_freq = 60,
	position = "right",
	padding_left = 0,
	padding_right = 5,
	y_offset = -5,
	label = { font = { family = settings.default, size = 9 } },
	click_script = click_script,
})
local function update_disk()
	sbar.exec("df -k /System/Volumes/Data | tail -1 | awk '{print $3, $2, $5}' | tr -d '%'", function(output)
		local used_kb, total_kb, percent = output:match("(%d+)%s+(%d+)%s+(%d+)")
		used_kb = tonumber(used_kb) or 0
		total_kb = tonumber(total_kb) or 1
		percent = tonumber(percent) or 0

		-- Convert KB → GB (decimal base-10) and round to nearest whole number
		local used_gb = math.floor((used_kb * 1024 / 1e9) + 0.5)
		local total_gb = math.floor((total_kb * 1024 / 1e9) + 0.5)

		local icon = ""
		local color = colors.green

		if percent >= 95 then
			icon = "󰪥"
			color = colors.red
		elseif percent >= 88 then
			icon = "󰪤"
			color = colors.orange
		elseif percent >= 76 then
			icon = "󰪣"
			color = colors.orange
		elseif percent >= 64 then
			icon = "󰪢"
			color = colors.yellow
		elseif percent >= 52 then
			icon = "󰪡"
			color = colors.yellow
		elseif percent >= 40 then
			icon = "󰪠"
			color = colors.green
		elseif percent >= 28 then
			icon = "󰪟"
			color = colors.green
		elseif percent >= 16 then
			icon = "󰪞"
			color = colors.green
		else
			icon = "󰝦"
			color = colors.green
		end

		disk_icon:set({
			icon = { string = icon, color = color },
		})
		disk_label:set({
			label = {
				string = string.format("%d/%dGB", used_gb, total_gb),
				color = color,
			},
		})
	end)
end
-- Subscriptions for both
disk_icon:subscribe({ "routine", "forced", "system_woke" }, update_disk)
disk_label:subscribe({ "routine", "forced", "system_woke" }, update_disk)

-- Initial update
update_disk()
