local colors = require("colors")

local dnd = sbar.add("item", "dnd", {
	label = {
		drawing = true,
		string = "􀆺",
		font = { size = 15 },
	},
	position = "right",
	click_script = 'osascript -e \'tell application "Shortcuts" to run shortcut "Toggle DND"\'',
	padding_right = 20,
	update_freq = 3,
})

-- Simple update function — single sbar.exec call
local function update_dnd()
	sbar.exec(
		"defaults read com.apple.controlcenter 'NSStatusItem VisibleCC FocusModes' 2>/dev/null | tr -d '%'",
		function(result)
			if result:match("1") then
				dnd:set({ label = { color = colors.purple } })
			else
				dnd:set({ label = { color = colors.grey } })
			end
		end
	)
end

-- Subscribe your DND item to the events
dnd:subscribe({ "routine", "system_woke" }, update_dnd)

update_dnd()
