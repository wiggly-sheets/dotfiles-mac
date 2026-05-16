local colors = require("colors")
local icons = require("helpers.icons")

local caffeinate = sbar.add("item", "caffeinate", {
	position = "right",
	update_freq = 10,
	padding_left = 0,
	padding_right = -2,
	icon = {
		color = colors.white,
	},
})

local caffeinated = false

local function set_icon(active)
	caffeinate:set({
		icon = { string = active and icons.caffeinate.on or icons.caffeinate.off, font = { size = 13 } },
	})
end

local function update_caffeinate()
	sbar.exec("pmset -g assertions | grep -c caffeinate", function(result)
		caffeinated = (tonumber(result) or 0) > 0
		set_icon(caffeinated)
	end)
end

local function toggle_caffeinate()
	caffeinated = not caffeinated
	set_icon(caffeinated)
	if caffeinated then
		sbar.exec("caffeinate -dimsu &")
	else
		sbar.exec("pkill caffeinate")
	end
end

caffeinate:subscribe("mouse.clicked", function()
	toggle_caffeinate()
end)

update_caffeinate()

caffeinate:subscribe("mouse.clicked", toggle_caffeinate)
caffeinate:subscribe("routine", update_caffeinate)

-- ======== Hover effects ========
local function add_hover(item)
	item:subscribe("mouse.entered", function()
		item:set({
			background = {
				drawing = true,
				color = colors.hover,
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

add_hover(caffeinate)
