local colors = require("colors")

local display = sbar.add("item", "display", {
	icon = {
		drawing = true,
		font = { family = "SF Pro", size = 12 },
		color = colors.white,
		padding_right = 4,
		padding_left = -2,
	},
	label = {
		drawing = true,
		font = { family = "Inconsolata Nerd Font Mono" },
		color = colors.yellow,
		padding_right = 0,
	},
	position = "right",
	click_script = 'osascript -e \'tell application "System Events" to keystroke "d" using {command down, option down, control down}\'',
})

local function update_display()
	local icons = {
		main_only = "􀟛",
		secondary_only = "􀙗",
		both = "􂤓",
		none = "􀁟",
	}

	local results = {}

	local function get_brightness(display_name, callback)
		local cmd = string.format('betterdisplaycli get --n="%s" --brightness=%%', display_name)
		sbar.exec(cmd, function(result)
			local value = tonumber(result)
			if value then
				callback(math.floor(value * 100))
			else
				callback(nil)
			end
		end)
	end

	get_brightness("built-in", function(main_brightness)
		results["main"] = main_brightness
		get_brightness("sceptre", function(secondary_brightness)
			results["secondary"] = secondary_brightness

			local label = ""
			local icon = icons.none

			if results["main"] and results["secondary"] then
				icon = icons.both
				label = string.format("%d%% & %d%%", results["secondary"], results["main"])
			elseif results["secondary"] then
				icon = icons.secondary_only
				label = string.format("%d%%", results["secondary"])
			elseif results["main"] then
				icon = icons.main_only
				label = string.format("%d%%", results["main"])
			else
				icon = icons.none
				label = "?"
			end

			display:set({
				icon = { string = icon, color = colors.white },
				label = { string = label, color = colors.yellow },
			})
		end)
	end)
end

-- Subscribe to system/display events (no timed polling)
display:subscribe({ "display_change", "brightness_change", "system_woke" }, update_display)

-- Run once at load
update_display()
