local settings = require("settings")
local colors = require("colors")
local icons = require("icons")

local temp_colors = {
	{ max = 40, color = colors.green }, -- Cool
	{ max = 60, color = colors.yellow }, -- Normal/Moderate
	{ max = 75, color = colors.orange }, -- Warm
	{ max = 90, color = colors.red }, -- Hot
}

-- Function to get color for a given temp
local function get_temp_color(temp)
	for _, range in ipairs(temp_colors) do
		if temp <= range.max then
			return range.color
		end
	end
	return colors.magenta -- fallback
end

local cpu_item = sbar.add("item", "cpu_temp", {
	update_freq = 10,
	position = "right",
	padding_left = -52,
	y_offset = -5,
	icon = icons.cpu,
	label = "",
	font = {
		family = settings.default,
	},
})
local gpu_item = sbar.add("item", "gpu_temp", {
	update_freq = 10,
	position = "right",
	y_offset = 10,
	icon = "􀧓",
	label = "",
	font = {
		family = settings.default,
	},
})

-- Function to update temperatures
local function update_temperatures()
	-- CPU temperature
	sbar.exec("smctemp -c -i25 -n180 -f", function(cpu_out)
		local cpu_temp = tonumber(cpu_out)
		cpu_item:set({
			label = {
				string = cpu_temp .. "°C",
				color = get_temp_color(cpu_temp),
			},
		})
	end)
end
-- GPU temperature
sbar.exec("smctemp -g -i25 -n180 -f", function(gpu_out)
	local gpu_temp = tonumber(gpu_out)
	gpu_item:set({
		label = {
			string = gpu_temp .. "°C",
			color = get_temp_color(gpu_temp),
		},
	})
end)

-- Subscribe to events
cpu_item:subscribe({ "routine", "forced", "system_woke" }, update_temperatures)
gpu_item:subscribe({ "routine", "forced", "system_woke" }, update_temperatures)

-- Initial update
update_temperatures()
