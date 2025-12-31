local icons = require("icons")
local colors = require("colors")
local settings = require("default")

-- Execute the event provider binary which provides the event "cpu_update" for
-- the cpu load data, which is fired every 3.0 seconds.
sbar.exec("killall cpu_load >/dev/null; $CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 3.0")

local cpu = sbar.add("graph", "cpu", 42, {
	position = "right",
	background = {
		height = 22,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
		padding_right = 8,
	},
	icon = { string = icons.cpu, padding_right = 0, padding_left = 0, color = colors.white },
	label = {
		string = "cpu __%",
		font = {
			family = settings.default,
			size = 8,
		},
		align = "right",
		width = 0,
		y_offset = 10,
	},

	updates = true,
	update_freq = 30,
})

cpu:subscribe("cpu_update", function(env)
	-- Also available: env.user_load, env.sys_load
	local load = tonumber(env.total_load)
	cpu:push({ load / 100. })

	local color = colors.green

	if load >= 90 then
		color = colors.red
	elseif load >= 70 then
		color = colors.orange
	elseif load >= 40 then
		color = colors.yellow
	end
	cpu:set({
		graph = { color = color },
		label = { color = color, string = "CPU " .. load .. "%" },
	})
end)

-- Background around the cpu item
sbar.add("bracket", "cpu.bracket", { cpu.name }, {
	background = { color = colors.bg1 },
})

-- Background around the cpu item
sbar.add("item", "cpu.padding", {
	position = "right",
	width = settings.group_paddings,
})

local ram = sbar.add("graph", "ram", 42, {
	position = "right",
	padding_right = -5,
	background = {
		height = 22,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
	},
	icon = { string = icons.ram, padding_right = 0, color = colors.white },
	label = {
		string = "ram __%",
		font = {
			family = settings.default,
			size = 8,
		},
		align = "right",
		width = 0,
		y_offset = 10,
	},
	update_freq = 30,
	updates = true,
})

sbar.add("bracket", "ram.bracket", { ram.name }, {
	background = { color = colors.bg1 },
})

sbar.add("item", "ram.padding", {
	position = "right",
	width = settings.group_paddings,
})
ram:subscribe({ "routine", "forced", "system_woke" }, function(env)
	sbar.exec("memory_pressure", function(output)
		local percentage = output:match("System%-wide memory free percentage: (%d+)")
		local load = 100 - tonumber(percentage)
		ram:push({ load / 100. })

		local color = colors.green
		if load >= 90 then
			color = colors.red
		elseif load >= 75 then
			color = colors.orange
		elseif load >= 50 then
			color = colors.yellow
		end

		ram:set({
			graph = { color = color },
			label = { color = color, string = "RAM " .. load .. "%" },
		})
	end)
end)
-- ======== Hover effects ========
local function add_hover(item)
	item:subscribe("mouse.entered", function()
		item:set({
			background = {
				drawing = true,
				color = 0x40FFFFFF,
				corner_radius = 20,
				height = 22,
				x_offset = 0,
			},
		})
	end)

	item:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
		item:set({ background = { drawing = true, height = 22, color = colors.transparent } })
	end)
end

add_hover(cpu)
add_hover(ram)

local left_cpu_click =
	'osascript -e \'tell application "System Events" to keystroke ";" using {command down, option down, control down}\''

local right_cpu_click =
	'osascript -e \'tell application "System Events" to keystroke "g" using {command down, option down, control down}\''

cpu:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(left_cpu_click)
	elseif env.BUTTON == "right" then
		sbar.exec(right_cpu_click)
	end
end)

local left_ram_click =
	'osascript -e \'tell application "System Events" to keystroke "z" using {command down, option down, control down}\''

ram:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(left_ram_click)
	else
	end
end)
