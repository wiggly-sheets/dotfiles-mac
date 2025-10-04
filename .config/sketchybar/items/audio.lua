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
	padding_right = -15,
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
local colors = require("colors")
local icons = require("icons")

local mic = sbar.add("item", "mic", {
	icon = {
		drawing = true,
		string = icons.mic.on,
		font = { family = "SF Pro", size = 12 },
		color = colors.white,
		padding_right = 8,
	},
	label = {
		padding_right = 3,
		drawing = true,
		width = "dynamic",
		string = "??",
		font = { family = "Inconsolata Nerd Font Mono" },
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
				icon = { string = "􀊳" },
				label = { string = "0%" },
			})
		else
			-- Mic is unmuted and volume > 0
			mic:set({
				icon = { string = "􀊱" },
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

volume_percent:subscribe("volume_change", function(env)
	local volume = tonumber(env.INFO)
	local icon = icons.volume._0
	if volume > 60 then
		icon = icons.volume._100
	elseif volume > 30 then
		icon = icons.volume._66
	elseif volume > 10 then
		icon = icons.volume._33
	elseif volume > 0 then
		icon = icons.volume._10
	end

	volume_icon:set({ label = icon })

	volume_percent:set({ label = volume .. "%" })

	sbar.exec('osascript -e "set volume output volume (output volume of (get volume settings) + ' .. delta .. ')"')
end)
