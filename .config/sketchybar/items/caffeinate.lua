local colors = require("colors")
local caffeinate = sbar.add("item", "caffeinate", {
	position = "right",
	update_freq = 10,
	padding_left = 2,
	padding_right = 2,
	icon = {
		color = colors.white,
	},
})

-- Function to check if a caffeinate process is active
local function is_caffeinated(callback)
	sbar.exec("pmset -g assertions | grep caffeinate", function(result)
		if result:match("caffeinate") then
			callback(true)
		else
			callback(false)
		end
	end)
end

local function update_caffeinate()
	is_caffeinated(function(active)
		if active then
			caffeinate:set({
				icon = { string = "􀸙", font = { size = 14 } },
			})
		else
			caffeinate:set({
				icon = { string = "􀸘", font = { size = 14 } },
			})
		end
	end)
end

local function toggle_caffeinate()
	is_caffeinated(function(active)
		if active then
			-- Kill caffeinate process
			sbar.exec("pkill caffeinate", function()
				update_caffeinate()
			end)
		else
			-- Start caffeinate
			sbar.exec("caffeinate -dimsu &", function()
				update_caffeinate()
			end)
		end
	end)
end

caffeinate:subscribe("mouse.clicked", toggle_caffeinate)
caffeinate:subscribe("routine", "forced", update_caffeinate)

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

add_hover(caffeinate)

-- Initialize on startup
update_caffeinate()
