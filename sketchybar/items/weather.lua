local weather_vars = require("helpers.weather_vars")
local colors = require("colors")
local settings = require("default")
local icons = require("icons")

-- Condition codes grouped by icon type (shorter + easier to maintain)
local condition_groups = {
	clear = { 1000 },
	partly = { 1003 },
	cloud = { 1006, 1009 },

	fog = { 1030, 1135, 1147 },

	rain = {
		1063,
		1072,
		1150,
		1153,
		1168,
		1171,
		1180,
		1183,
		1186,
		1189,
		1192,
		1195,
		1198,
		1201,
	},

	shower = { 1240, 1243, 1246 },

	snow = {
		1066,
		1114,
		1117,
		1210,
		1213,
		1216,
		1219,
		1222,
		1225,
		1255,
		1258,
	},

	sleet = { 1069, 1204, 1207, 1249, 1252 },

	ice = { 1237, 1261, 1264 },

	thunder = { 1087, 1273, 1276 },

	snow_thunder = { 1279, 1282 },
}

-- Build lookup table used by get_icon()
local conditions = {}
for group, codes in pairs(condition_groups) do
	for _, code in ipairs(codes) do
		conditions[code] = group
	end
end

local weather = sbar.add("item", "weather", {
	position = "right",
	update_freq = 600,
	icon = {
		font = { family = settings.default, style = "Regular", size = 13 },
		padding_right = 0,
		padding_left = 10,
		y_offset = 6,
	},
	label = {
		padding_right = 0,
		padding_left = -18,
		y_offset = -6,
		font = {
			family = settings.default,
			style = settings.default,
			size = 10,
		},
	},
})

local function get_icon(code, is_day)
	local period = is_day == 1 and "day" or "night"
	local group = conditions[code] or "cloud"
	return icons.weather[period][group]
end

-- Temperature → Color mapping

local function get_temp_color(temp)
	if temp <= 40 then
		return colors.blue
	elseif temp <= 60 then
		return colors.green
	elseif temp <= 75 then
		return colors.yellow
	elseif temp <= 85 then
		return colors.orange
	else
		return colors.red
	end
end

-- Weather condition → Icon color mapping
local function get_condition_color(code)
	local group = conditions[code] or "cloud"

	local map = {
		clear = colors.yellow, -- bright sun
		partly = colors.yellow, -- still sun-dominant
		cloud = colors.white, -- neutral clouds
		fog = colors.grey, -- muted visibility
		rain = colors.blue, -- water / rain
		shower = colors.blue, -- same family as rain
		snow = colors.white, -- snow
		sleet = colors.blue, -- icy precipitation
		ice = colors.blue, -- frozen water
		thunder = colors.orange, -- lightning / storm energy
		snow_thunder = colors.magenta, -- unusual / severe combo
	}

	return map[group] or colors.white
end

local function update_weather()
	local url = string.format(
		"curl -s 'http://api.weatherapi.com/v1/forecast.json?key=%s&q=%s&days=1'",
		weather_vars.api_key,
		weather_vars.location or "auto:ip"
	)

	sbar.exec(url, function(data)
		local temp = math.floor(data.current.temp_f)
		local code = data.current.condition.code
		local icon = get_icon(code, data.current.is_day)
		local temp_color = get_temp_color(temp)
		local icon_color = get_condition_color(code)

		weather:set({
			icon = {
				string = icon,
				color = icon_color,
			},
			label = {
				string = string.format("%s°F", temp),
				color = temp_color,
			},
		})
	end)
end

weather:subscribe({ "forced", "routine", "system_woke" }, function()
	update_weather()
end)

local left_click_script =
	'osascript -e \'tell application "System Events" to tell process "Sparrow" to click menu bar item 1 of menu bar 2\''
local right_click_script = "open -a Weather"

weather:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(left_click_script)
	elseif env.BUTTON == "right" then
		sbar.exec(right_click_script)
	end
end)

-- Hover effects
local function add_hover(item)
	item:subscribe("mouse.entered", function()
		item:set({
			background = {
				drawing = true,
				color = colors.hover,
				corner_radius = 20,
				height = 20,
				x_offset = 2,
			},
		})
	end)

	item:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
		item:set({ background = { drawing = false } })
	end)
end

add_hover(weather)
