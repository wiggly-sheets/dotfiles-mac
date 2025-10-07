local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local volume_percent = sbar.add("item", "widgets.volume1", {
	position = "right",
	icon = { drawing = false },
	label = {
		string = "??%",
		padding_right = 0,
		padding_left = 12,
		width = "dynamic",
		color = colors.yellow,
		font = { style = settings.default },
	},
	click_script = 'osascript -e \'tell application "System Events" to tell process "SoundSource" to click menu bar item 1 of menu bar 2\'',
})

local volume_icon = sbar.add("item", "widgets.volume2", {
	position = "right",
	padding_right = -18,
	padding_left = 0,
	drawing = true,
	color = colors.yellow,
	icon = {
		drawing = false,
		string = icons.volume._10,
		width = "dynamic",
		color = colors.yellow,
		font = {
			style = settings.font.style_map["Medium"],
			size = 12.0,
		},
	},
	label = {
		width = "dynamic",
		padding_right = 5,
		drawing = true,
		font = {
			style = settings.font.style_map["Medium"],
			size = 13.0,
			color = colors.yellow,
		},
	},
	click_script = 'osascript -e \'tell application "System Events" to tell process "SoundSource" to click menu bar item 1 of menu bar 2\'',
})

local mic = sbar.add("item", "mic", {
	icon = {
		drawing = true,
		string = icons.mic.on,
		font = { size = 12 },
		color = colors.white,
		padding_right = 6,
		padding_left = 0,
	},
	label = {
		padding_right = 1,
		drawing = true,
		width = "dynamic",
		string = "??",
		font = { family = settings.default },
		color = colors.yellow,
	},
	position = "right",
	update_freq = 5,
	click_script = 'osascript -e \'tell application "System Events" to tell process "SoundSource" to click menu bar item 1 of menu bar 2\'',
})

-- Function to update mic icon/label
local function update_mic()
	sbar.exec("osascript -e 'set volInfo to input volume of (get volume settings)'", function(result)
		local volume = tonumber(result)

		if not volume then
			-- No valid input volume detected
			mic:set({
				icon = { string = "􀊳" },
				label = { string = "" },
			})
		elseif volume == 0 then
			-- Volume is zero but not muted
			mic:set({
				icon = { string = icons.mic.off },
				label = { string = "0%" },
			})
		else
			-- Mic is unmuted and volume > 0
			mic:set({
				icon = { string = icons.mic.on },
				label = { string = volume .. "%" },
			})
		end
	end)
end

-- Subscribe to routine updates
mic:subscribe({ "routine" }, update_mic)

-- Initialize at startup
update_mic()

local volume_bracket = sbar.add("bracket", "widgets.volume.bracket", {
	volume_icon.name,
	volume_percent.name,
}, {
	background = { color = colors.transparent },
	popup = { align = "center" },
})

local function update_output_device_icon(volume)
	sbar.exec("/opt/homebrew/bin/SwitchAudioSource -c", function(result)
		local device = result:gsub("\n", "")
		local icon

		-- Device-specific icons
		if device:match("AirPods Pro") then
			icon = "􀪷" -- AirPods Pro
		elseif device:match("AirPods Max") then
			icon = "􀺹" -- AirPods Max
		elseif device:match("Scarlett 2i2") then
			icon = "􂡒" -- Scarlett 2i2 USB
		elseif device:match("Sceptre") then
			icon = "􀢹"
		else
			-- Fallback: use your existing volume-based icons
			if volume == nil then
				volume = 0
			end
			if volume > 60 then
				icon = icons.volume._100
			elseif volume > 30 then
				icon = icons.volume._66
			elseif volume > 10 then
				icon = icons.volume._33
			elseif volume > 0 then
				icon = icons.volume._10
			else
				icon = icons.volume._0
			end
		end

		volume_icon:set({ label = icon })
	end)
end

-- Update both percent and icon when volume changes
volume_percent:subscribe("volume_change", function(env)
	local volume = tonumber(env.INFO) or 0

	-- Update the percent display
	volume_percent:set({ label = volume .. "%" })

	-- Refresh icon depending on device
	update_output_device_icon(volume)
end)

-- Periodic refresh to catch device switches (every routine tick)
volume_icon:subscribe("routine", function()
	update_output_device_icon()
end)
