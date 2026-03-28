local colors = require("colors")
local icons = require("icons")

local dnd = sbar.add("item", "dnd", {
	label = {
		drawing = true,
		string = icons.dnd,
		font = { size = 15 },
	},
	position = "right",
	padding_right = 4,
	padding_left = 0,
	update_freq = 10,
	y_offset = 1,
})

local function update_dnd()
	sbar.exec(
		[[defaults read com.apple.controlcenter 'NSStatusItem VisibleCC FocusModes' 2>/dev/null]],
		function(result)
			if result:match("1") then
				dnd:set({ label = { color = colors.dnd } })
			else
				dnd:set({ label = { color = colors.grey } })
			end
		end
	)
end

local left_click_script = 'osascript -e \'tell application "Shortcuts" to run shortcut "Toggle DND"\''

local right_click_script =
	'osascript -e \'tell application "System Events" to tell process "ControlCenter" to click menu bar item 5 of menu bar 1\''

dnd:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(left_click_script)
	elseif env.BUTTON == "right" then
		sbar.exec(right_click_script)
	end
end)

-- Subscribe your DND item to the events
dnd:subscribe({ "routine", "system_woke" }, update_dnd)

-- ======== Hover effects ========
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

add_hover(dnd)

update_dnd()
