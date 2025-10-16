local colors = require("colors")
local settings = require("settings")

-- ======================
-- Click scripts
-- ======================

local display_left_click =
	'osascript -e \'tell application "System Events" to keystroke "d" using {command down, option down, control down}\''

local display_right_click =
	'osascript -e \'tell application "System Events" to tell process "Control Center" to click menu bar item 5 of menu bar 1\''

local function handle_display_click(env)
	if env.BUTTON == "left" then
		sbar.exec(display_left_click)
	elseif env.BUTTON == "right" then
		sbar.exec(display_right_click)
	end
end

-- ======================
-- Display item
-- ======================

local display = sbar.add("item", "display", {
	icon = {
		drawing = true,
		font = { size = 12 },
		color = colors.white,
		padding_right = 4,
		padding_left = 0,
	},
	label = {
		drawing = true,
		font = { family = settings.default, size = 12 },
		color = colors.yellow,
		padding_right = 0,
	},
	position = "right",
})

-- Subscribe to mouse clicks
display:subscribe("mouse.clicked", handle_display_click)

-- ======================
-- Update function
-- ======================

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

-- Subscribe to display/system events
display:subscribe({ "display_change", "brightness_change", "system_woke" }, update_display)

-- Initial update
update_display()
