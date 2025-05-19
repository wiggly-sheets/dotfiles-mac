local colors = require("colors")

local display_item = sbar.add("item", "display", {
	icon = {
		drawing = true,
		-- Default icon, assuming a laptop if no external display is present.
		string = "􀟛",
		font = { family = "SF Pro", size = 13 },
		color = colors.white,
		padding_right = 0,
		padding_left = 0,
	},
	label = {
		drawing = true,
		font = { family = "IosevkaTermSlab Nerd Font Mono", size = 13 },
		color = colors.yellow,
		padding_left = 8,
	},
	position = "right",
	update_freq = 10,
	click_script = "cliclick kd:ctrl,alt,cmd t:b",
	padding_left = 0,
	padding_right = 0,
	script = "/Users/zeb/dotfiles/.config/sketchybar/helpers/scripts/display_percent.sh",
})

-- Function: Count the displays using system_profiler
local function count_displays()
	-- This command lists the displays; we grep for "Display:" and count the matching lines.
	local handle = io.popen('system_profiler SPDisplaysDataType | grep "Display:" | wc -l')
	if not handle then
		return 1
	end
	local output = handle:read("*a")
	handle:close()
	output = output:gsub("%s+", "") -- Remove whitespace/newlines.
	return tonumber(output) or 1
end

-- Function: Update the display icon based on the display count.
local function update_display_icon()
	local count = count_displays()
	if count > 1 then
		-- More than one display: use the desktop monitor icon.
		display_item:set({
			icon = {
				string = "􂤓", -- Replace with your preferred SF Symbol for a desktop monitor.
				color = colors.white,
			},
		})
	else
		-- One display only: use the laptop icon.
		display_item:set({
			icon = {
				string = "􀟛", -- Replace with your preferred SF Symbol for a laptop.
				color = colors.white,
			},
		})
	end
end

-- Perform an immediate update.
update_display_icon()
