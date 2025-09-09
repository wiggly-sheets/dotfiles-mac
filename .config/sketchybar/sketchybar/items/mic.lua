local colors = require("colors")
local icons = require("icons")

local mic_item = sbar.add("item", "mic", {
	icon = {
		drawing = true,
		string = icons.mic.on, -- Default unmuted mic icon.
		font = { family = "SF Pro", size = 13 },
		color = colors.white,
	},
	label = {
		drawing = true,
		width = "dynamic",
		padding_left = 5,
		padding_right = 0,
		string = "??", -- Default volume text.
		font = { family = "Inconsolata Nerd Font Mono" },
		color = colors.yellow,
	},
	position = "right",
	padding_left = 0,
	padding_right = -5,
	update_freq = 1,
	script = "~/.config/sketchybar/helpers/scripts/mic.sh",
	click_script = 'osascript -e \'tell application "System Events" to tell process "SoundSource" to click menu bar item 1 of menu bar 2\'',
})

-- Function to update the mic item based on current input volume.
local function update_mic_status()
	local handle = io.popen("osascript -e 'input volume of (get volume settings)'")
	if not handle then
		print("Error:could not open process")
		return
	end
	local vol_str = handle:read("*a")
	handle:close()
	-- Trim whitespace from the output
	vol_str = vol_str:gsub("^%s*(.-)%s*$", "%1")
	local volume = tonumber(vol_str) or 0

	if volume == 0 then
		mic_item:set({
			icon = { string = icons.mic.muted, color = colors.white },
			label = { string = "0%" },
		})
	else
		mic_item:set({
			icon = { string = icons.mic.on, color = colors.white },
			label = { string = tostring(volume) .. "%" },
		})
	end
end

-- Perform the update immediately.
update_mic_status()
