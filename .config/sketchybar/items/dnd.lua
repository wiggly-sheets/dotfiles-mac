local colors = require("colors")

local dnd = sbar.add("item", "dnd", {
	label = {
		drawing = true,
		string = "􀆺",
		font = { size = 15 },
	},
	position = "right",
	padding_right = 8,
	padding_left = 5,
	update_freq = 10,
})

local function update_dnd()
	sbar.exec(
		[[defaults read com.apple.controlcenter 'NSStatusItem VisibleCC FocusModes' 2>/dev/null]],
		function(result)
			if result:match("1") then
				dnd:set({ label = { color = colors.dnd } }) -- hardcoded purple because it's different than magenta in color config to match system icon
			else
				dnd:set({ label = { color = colors.grey } })
			end
		end
	)
end

local left_click_script = 'osascript -e \'tell application "Shortcuts" to run shortcut "Toggle DND"\''

local right_click_script =
	'osascript -e \'tell application "System Events" to tell process "ControlCenter" to click menu bar item 0 of menu bar 1\''

dnd:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(left_click_script)
	elseif env.BUTTON == "right" then
		sbar.exec(right_click_script)
	end
end)

-- Subscribe your DND item to the events
dnd:subscribe({ "routine", "system_woke" }, update_dnd)

update_dnd()
