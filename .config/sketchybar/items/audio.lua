local colors = require("colors")
local icons = require("icons")
local settings = require("default")

-- Volume item
local volume_item = sbar.add("item", "volume", {
	position = "right",
	padding_left = 0,
	padding_right = 5,
	color = colors.yellow,
	icon = {
		drawing = true,
		string = icons.volume._0,
		width = "dynamic",
		color = colors.yellow,
		font = { family = settings.default, size = 12.0 },
	},
	label = {
		drawing = true,
		string = "__%",
		width = "dynamic",
		padding_left = 5,
		padding_right = 0,
		color = colors.yellow,
		font = { family = settings.default, size = 10.0 },
	},
})

-- Mic item
local mic_item = sbar.add("item", "mic", {
	icon = {
		drawing = true,
		string = icons.mic.on,
		font = { size = 12 },
		color = colors.white,
		padding_right = 2,
		padding_left = 6,
	},
	label = {
		padding_right = 3,
		padding_left = 3,
		drawing = true,
		width = "dynamic",
		string = "??",
		font = { family = settings.default, size = 10 },
		color = colors.yellow,
	},
	position = "right",
	update_freq = 5,
})

-- ======== Mic update function ========
local function update_mic()
	sbar.exec("osascript -e 'set volInfo to input volume of (get volume settings)'", function(result)
		local vol = tonumber(result)

		if not vol then
			mic_item:set({ icon = { string = "" }, label = { string = "" } })
		elseif vol == 0 then
			mic_item:set({ icon = { string = icons.mic.muted }, label = { string = "0%" } })
		else
			mic_item:set({ icon = { string = icons.mic.on }, label = { string = vol .. "%" } })
		end
	end)
end

mic_item:subscribe({ "routine" }, update_mic)

update_mic()

-- ======== Volume update subscriptions ========
volume_item:subscribe("volume_change", function(env)
	local volume = tonumber(env.INFO) or 0
	volume_item:set({ label = volume .. "%" })
	sbar.exec("/opt/homebrew/bin/SwitchAudioSource -c", function(device)
		device = device:gsub("\n", ""):match("^%s*(.-)%s*$")
		local icon
		if device:match("AirPods Pro") then
			icon = "􀪷"
		elseif device:match("AirPods Max") then
			icon = "􀺹"
		elseif device:match("Scarlett 2i2") then
			icon = "􂡒"
		elseif device:match("Sceptre") then
			icon = "􀢹"
		else
			if volume == nil then
				volume = 0
			end
			if volume >= 75 then
				icon = icons.volume._100
			elseif volume >= 40 then
				icon = icons.volume._66
			elseif volume >= 20 then
				icon = icons.volume._33
			elseif volume > 0 then
				icon = icons.volume._10
			else
				icon = icons.volume._0
			end
		end
		volume_item:set({ icon = icon })
	end)
end)

-- ======== Click handling ========
local left_click_script =
	'osascript -e \'tell application "System Events" to tell process "SoundSource" to click menu bar item 1 of menu bar 2\''
local right_click_script =
	'osascript -e \'tell application "System Events" to tell process "ControlCenter" to click (first menu bar item of menu bar 1 whose name is not "Wi-Fi")\''
local middle_click_script =
	'osascript -e \'tell application "System Events" to tell process "SystemUIServer" to click menu bar item 2 of menu bar 1\''

local function handle_volume_click(env)
	if env.BUTTON == "left" then
		sbar.exec(left_click_script)
	elseif env.BUTTON == "right" then
		sbar.exec(right_click_script)
	else
		sbar.exec(middle_click_script)
	end
end

volume_item:subscribe("mouse.clicked", handle_volume_click)
mic_item:subscribe("mouse.clicked", handle_volume_click)

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

add_hover(volume_item)
add_hover(mic_item)
