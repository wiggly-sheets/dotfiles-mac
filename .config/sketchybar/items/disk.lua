local settings = require("default")
local colors = require("colors")

-- Disk icon item
local disk_icon = sbar.add("item", "disk_icon", {
	update_freq = 60,
	position = "right",
	padding_left = -34,
	padding_right = 20,
	y_offset = 8,
	icon = { font = { size = 14 } },
})

-- Disk label item
local disk_label = sbar.add("item", "disk_label", {
	update_freq = 60,
	position = "right",
	padding_left = -2,
	padding_right = 0,
	y_offset = -5,
	label = { font = { family = settings.default, size = 9 } },
})

-- Update disk icon/label (used/total) only
local function update_disk()
	sbar.exec("/usr/local/bin/diskspace 2>&1", function(output)
		local available = tonumber(output:match("Available:%s*(%d+)")) or 0
		local total = tonumber(output:match("Total:%s*(%d+)")) or 1
		local used = total - available
		local percent = math.floor((used / total) * 100 + 0.5)

		local used_gb = math.floor(used / 1e9 + 0.5)
		local total_gb = math.floor(total / 1e9 + 0.5)

		local icon, color = "󰝦", colors.green
		if percent >= 95 then icon, color = "󰪥", colors.red
		elseif percent >= 88 then icon, color = "󰪤", colors.orange
		elseif percent >= 76 then icon, color = "󰪣", colors.orange
		elseif percent >= 64 then icon, color = "󰪢", colors.yellow
		elseif percent >= 52 then icon, color = "󰪡", colors.yellow
		elseif percent >= 40 then icon, color = "󰪠", colors.green
		elseif percent >= 28 then icon, color = "󰪟", colors.green
		elseif percent >= 16 then icon, color = "󰪞", colors.green
		end

		disk_icon:set({ icon = { string = icon, color = color } })
		disk_label:set({ label = { string = string.format("%d/%dGB", used_gb, total_gb), color = color } })
	end)
end

-- Left-click script (keyboard shortcut)
local left_click_script =
'osascript -e \'tell application "System Events" to keystroke "s" using {command down, option down, control down}\''

-- Handle clicks
local function handle_disk_click(env)
	if env.BUTTON == "left" then
		sbar.exec(left_click_script)
	elseif env.BUTTON == "right" then
	end
end

-- Subscribe items
disk_icon:subscribe("mouse.clicked", handle_disk_click)
disk_label:subscribe("mouse.clicked", handle_disk_click)
disk_icon:subscribe({ "routine", "forced", "system_woke" }, update_disk)
disk_label:subscribe({ "routine", "forced", "system_woke" }, update_disk)

-- Initial update
update_disk()