local colors = require("colors")

local folder = sbar.add("item", "folder", {
	icon = {
		font = { size = 13.5 },
		string = "􀈖",
		color = colors.white,
	},
	position = "right",
})

local left_click_script =
	'osascript -e \'tell application "System Events" to tell process "Default Folder X" to click menu bar item 1 of menu bar 2\''

local right_click_script =
	'osascript -e \'tell application "System Events" to tell process "Mountain Duck" to click menu bar item 1 of menu bar 1\''

local middle_click_script =
	'osascript -e \'tell application "System Events" to tell process "MountMate" to click menu bar item 1 of menu bar 2\''

folder:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec(left_click_script)
	elseif env.BUTTON == "right" then
		sbar.exec(right_click_script)
	else
		sbar.exec(middle_click_script)
	end
end)
