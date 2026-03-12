local weather_vars = require("helpers.weather_vars")
local colors = require("colors")
local settings = require("default")

local icons = {
	day = {
		clear = "",
		partly = "",
		cloud = "",
		fog = "",
		rain = "",
		shower = "",
		snow = "",
		sleet = "",
		ice = "",
		thunder = "",
		snow_thunder = "",
	},
	night = {
		clear = "",
		partly = "",
		cloud = "",
		fog = "",
		rain = "",
		shower = "",
		snow = "",
		sleet = "",
		ice = "",
		thunder = "",
		snow_thunder = "",
	},
}

local conditions = {
	[1000] = "clear",
	[1003] = "partly",
	[1006] = "cloud",
	[1009] = "cloud",

	[1030] = "fog",
	[1135] = "fog",
	[1147] = "fog",

	[1063] = "rain",
	[1072] = "rain",
	[1150] = "rain",
	[1153] = "rain",
	[1168] = "rain",
	[1171] = "rain",
	[1180] = "rain",
	[1183] = "rain",
	[1186] = "rain",
	[1189] = "rain",
	[1192] = "rain",
	[1195] = "rain",
	[1198] = "rain",
	[1201] = "rain",

	[1240] = "shower",
	[1243] = "shower",
	[1246] = "shower",

	[1066] = "snow",
	[1114] = "snow",
	[1117] = "snow",
	[1210] = "snow",
	[1213] = "snow",
	[1216] = "snow",
	[1219] = "snow",
	[1222] = "snow",
	[1225] = "snow",
	[1255] = "snow",
	[1258] = "snow",

	[1069] = "sleet",
	[1204] = "sleet",
	[1207] = "sleet",
	[1249] = "sleet",
	[1252] = "sleet",

	[1237] = "ice",
	[1261] = "ice",
	[1264] = "ice",

	[1087] = "thunder",
	[1273] = "thunder",
	[1276] = "thunder",

	[1279] = "snow_thunder",
	[1282] = "snow_thunder",
}

local weather = sbar.add("item", "widgets.weather", {
	position = "right",
	update_freq = 3600, --30 min updates
	icon = {
		font = { family = settings.default, style = "Regular", size = 13 },
		padding_right = 0,
		padding_left = 5,
	},
	label = {
		padding_right = 2,
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
	return icons[period][group]
end

-- 🌡️ Temperature → Color mapping
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

local function update_weather()
	local url = string.format(
		"curl -s 'http://api.weatherapi.com/v1/forecast.json?key=%s&q=%s&days=1'",
		weather_vars.api_key,
		weather_vars.location or "auto:ip"
	)
	sbar.exec(url, function(data)
		local temp = math.floor(data.current.temp_f)
		local icon = get_icon(data.current.condition.code, data.current.is_day)
		local color = get_temp_color(temp)

		weather:set({
			icon = {
				string = icon,
				color = color,
			},
			label = {
				string = string.format("%s°F", temp),
				color = color,
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

-- ======== Hover effects ========
local function add_hover(item)
	item:subscribe("mouse.entered", function()
		item:set({
			background = {
				drawing = true,
				color = 0x40FFFFFF,
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
