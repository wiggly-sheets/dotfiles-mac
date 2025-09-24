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
	padding_left = -3,
	drawing = true,
	color = colors.yellow,
	icon = {
		drawing = false,
		string = icons.volume._10,
		width = "dynamic",
		color =colors.yellow,
		font = {
			style = settings.font.style_map["Medium"],
			size = 12.0,		},
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

local volume_bracket = sbar.add("bracket", "widgets.volume.bracket", {
	volume_icon.name,
	volume_percent.name,
}, {
	background = { color = colors.transparent },
	popup = { align = "center" },
})

sbar.add("item", "widgets.volume.padding", {
	position = "right",
	width = 10,
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
