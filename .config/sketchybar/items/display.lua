local colors = require("colors")
local settings = require("default")

-- ======================
-- Click scripts
-- ======================

local display_left_click =
	'osascript -e \'tell application "System Events" to keystroke "d" using {command down, option down, control down}\''

local display_wallper_click =
	'osascript -e \'tell application "System Events" to tell process "Wallper" to click menu bar item 1 of menu bar 2\''

local display_flux_click =
	'osascript -e \'tell application "System Events" to tell process "Flux" to click menu bar item 1 of menu bar 2\''

local display_switch_click =
	'p=$(yabai -m config external_bar); if [ "$p" = "all:0:0" ]; then yabai -m config external_bar main:9:0 && yabai -m config window_gap 10 && yabai -m config top_padding 0 && yabai -m config bottom_padding 10 && yabai -m config left_padding 10 && yabai -m config right_padding 10; else yabai -m config external_bar all:0:0 && yabai -m config window_gap 5 && yabai -m config top_padding 1 && yabai -m config bottom_padding 1 && yabai -m config left_padding 1 && yabai -m config right_padding 1; fi'

local function handle_display_click(env)
	if env.BUTTON == "left" then
		sbar.exec(display_left_click)
	elseif env.BUTTON == "right" then
		sbar.exec(display_flux_click)
	elseif env.BUTTON == "other" then
		sbar.exec(display_switch_click)
	elseif env.MODIFIER == "cmd" and env.BUTTON == "left" then
		sbar.exec(display_wallper_click)
	end
end

-- ======================
-- Display item
-- ======================

local display = sbar.add("item", "display", {
	icon = {
		drawing = true,
		font = { size = 11 },
		color = colors.white,
		padding_right = 4,
		padding_left = 0,
	},
	label = {
		drawing = true,
		font = { family = settings.default, size = 10 },
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

-- ======== Hover effects ========
local function add_hover(item)
	item:subscribe("mouse.entered", function()
		item:set({
			background = {
				drawing = true,
				color = 0x40FFFFFF,
				corner_radius = 20,
				height = 20,
				x_offset = 0,
			},
		})
	end)

	item:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
		item:set({ background = { drawing = false } })
	end)
end

add_hover(display)

-- Initial update
update_display()
