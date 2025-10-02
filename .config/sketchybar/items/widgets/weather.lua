local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local loc = require("utils.loc")
local tbl = require("utils.tbl")

-- Add the weather item
local weather = sbar.add("item", "widgets.weather", {
	position = "right",
	icon = { drawing = false },
	label = {
		string = icons.loading,
		font = { style = settings.default, size = 14 },
	},
	update_freq = 500,
	padding_right = -30,
	padding_left = 0,
	click_script = 'osascript -e \'tell application "System Events" to tell process "Sparrow" to click menu bar item 1 of menu bar 2\'',
})

-- Bracket for background
sbar.add("bracket", "widgets.weather.bracket", { weather.name }, {
	background = { color = colors.bg1 },
})

sbar.add("item", "widgets.weather.padding", {
	position = "right",
	width = 0,
})

-- Map weather condition to icon
local function map_condition_to_icon(cond)
	local condition = cond:lower():match("^%s*(.-)%s*$")
	if condition == "sunny" then
		return icons.weather.sunny
	elseif condition == "cloudy" or condition == "overcast" or condition == "haze" then
		return icons.weather.cloudy
	elseif condition == "clear" then
		return icons.weather.clear
	elseif string.find(condition, "storm") or string.find(condition, "thunder") then
		return icons.weather.stormy
	elseif string.find(condition, "partly") then
		return icons.weather.partly
	elseif string.find(condition, "sleet") or string.find(condition, "freez") then
		return icons.weather.sleet
	elseif string.find(condition, "rain") or string.find(condition, "drizzle") then
		return icons.weather.rainy
	elseif string.find(condition, "snow") or string.find(condition, "ice") then
		return icons.weather.snowy
	elseif string.find(condition, "mist") or string.find(condition, "fog") then
		return icons.weather.foggy
	end
	return "?"
end

-- Map temperature to a color
local function temp_to_color(tempF)
	local t = tonumber(tempF)
	if not t then
		return colors.white
	end

	if t <= 40 then
		return colors.blue -- cold
	elseif t <= 60 then
		return colors.green -- mild
	elseif t <= 80 then
		return colors.yellow -- warm
	else
		return colors.red -- hot
	end
end

-- Load weather and set icon/label
local function load_weather(weather_data)
	local current_condition = weather_data.current_condition[1]
	local temperature = current_condition.temp_F .. "°"
	local condition = current_condition.weatherDesc[1].value
	local color = temp_to_color(current_condition.temp_F)

	weather:set({
		icon = {
			string = map_condition_to_icon(condition),
			drawing = true,
			color = color,
		},
		label = {
			string = temperature,
			padding_left = -2,
			padding_right = 5,
			color = color,
		},
	})
end

-- Subscribe to events and fetch weather
weather:subscribe({ "routine", "forced", "system_woke" }, function()
	sbar.exec("ipconfig getifaddr en0", function(wifi)
		local loc_str = ""
		if settings.weather.use_shortcut and wifi ~= "" then
			sbar.exec('shortcuts run "Get Location" | tee', function(location)
				local loc_tbl = tbl.from_string(location)
				if loc_tbl and #loc_tbl > 2 then
					local country = loc_tbl[#loc_tbl]
					if country == "United States" then
						local region = loc_tbl[#loc_tbl - 1]
						local city, state, _ = region:match("^(.-)%s+(%a%a)%s+(%d%d%d%d%d)$")
						if city and state then
							loc_str = city .. "+" .. loc.state_abbrevation_to_name(state):gsub(" ", "+")
						end
					end
				end
			end)
		end
		if loc_str == "" and settings.weather.location then
			loc_str = settings.weather.location
		end
		sbar.exec('curl "wttr.in/' .. loc_str .. '?format=j1"', load_weather)
	end)
end)

