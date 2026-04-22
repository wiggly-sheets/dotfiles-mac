local colors = require("colors")
local icons = require("icons")
local settings = require("default")

local volume = sbar.add("item", "volume", {
	position = "right",
	y_offset = 6,
	icon = {
		padding_left = 2,
		padding_right = 2,
		drawing = true,
		string = icons.volume._0,
		width = "dynamic",
		color = colors.white,
		font = { family = settings.default, size = 11.0 },
	},
	label = {
		drawing = true,
		string = "__%",
		width = "dynamic",
		padding_left = 2,
		padding_right = 2,
		color = colors.yellow,
		font = { family = settings.default, size = 10.0 },
	},
	updates = "true",
})

local mic = sbar.add("item", "mic", {
	icon = {
		drawing = true,
		string = icons.mic.on,
		font = { size = 11 },
		color = colors.white,
		padding_right = 5,
		padding_left = 2,
	},
	label = {
		padding_right = 2,
		padding_left = 2,
		drawing = true,
		width = "dynamic",
		string = "??",
		font = { family = settings.default, size = 10 },
		color = colors.yellow,
	},
	position = "right",
	update_freq = 10,
	padding_right = -40,
	padding_left = 4,
	y_offset = -6,
})

local function update_mic()
	sbar.exec("osascript -e 'set volInfo to input volume of (get volume settings)'", function(result)
		local vol = tonumber(result)

		if not vol then
			mic:set({ icon = { string = "" }, label = { string = "" } })
		elseif vol == 0 then
			mic:set({ icon = { string = icons.mic.muted }, label = { string = "0%" } })
		else
			mic:set({ icon = { string = icons.mic.on }, label = { string = vol .. "%" } })
		end
	end)
end

mic:subscribe({ "routine", "volume_change", "forced", "system_woke" }, update_mic)

update_mic()

volume:subscribe("volume_change", "forced", "system_woke", function(env)
	local level = tonumber(env.INFO) or 0
	volume:set({ label = level .. "%" })
	sbar.exec("/opt/homebrew/bin/SwitchAudioSource -c", function(device)
		device = device:gsub("\n", ""):match("^%s*(.-)%s*$")
		local icon
		if device:match("AirPods Pro") then
			icon = icons.audio.airpods_pro
		elseif device:match("AirPods Max") then
			icon = icons.audio.airpods_max
		elseif device:match("Scarlett 2i2") then
			icon = icons.audio.scarlett
		elseif device:match("Sceptre") then
			icon = icons.audio.sceptre
		else
			if volume == nil then
				volume = 0
			end
			if volume >= 75 then
				icon = icons.volume._100
			elseif volume >= 50 then
				icon = icons.volume._66
			elseif volume >= 25 then
				icon = icons.volume._33
			elseif volume > 0 then
				icon = icons.volume._10
			else
				icon = icons.volume._0
			end
		end
		volume:set({ icon = icon })
	end)
end)

local left_click_script =
	'osascript -e \'tell application "System Events" to tell process "SoundSource" to click menu bar item 1 of menu bar 2\''

local right_click_script =
	'osascript -e \'tell application "System Events" to tell process "SystemUIServer" to click menu bar item 2 of menu bar 1\''

local function handle_volume_click(env)
	if env.BUTTON == "left" then
		sbar.exec(left_click_script)
	elseif env.BUTTON == "right" then
		sbar.exec(right_click_script)
	end
end

volume:subscribe("mouse.clicked", handle_volume_click)
mic:subscribe("mouse.clicked", handle_volume_click)

volume:subscribe("mouse.entered", function()
	volume:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			y_offset = 0,
		},
	})
	mic:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			x_offset = 0,
		},
	})
end)

mic:subscribe("mouse.entered", function()
	volume:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			y_offset = 0,
		},
	})
	mic:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			x_offset = 0,
		},
	})
end)

volume:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	volume:set({ background = { drawing = true, height = 20, color = colors.transparent } })
	mic:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)

mic:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	volume:set({ background = { drawing = true, height = 10, color = colors.transparent } })
	mic:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)
