local colors = require("colors")
local settings = require("settings")

-- Path to macOS Notification Center database
local notif_db = os.getenv("HOME") .. "/Library/Group Containers/group.com.apple.usernoted/db2/db"

-- Create the SketchyBar item
local notifications = sbar.add("item", "widgets.notifications", {
	position = "right",
	width = 5,
	y_offset = 14,
	padding_right = 10,
	icon = {
		string = "",
		color = colors.red,
		font = { family = settings.default, size = 10 },
	},
	label = {
		string = "",
		font = { family = settings.default, size = 12 },
	},
	drawing = true, -- keep its space reserved so layout doesn't shift
	update_freq = 30, -- check every 30 seconds
})

-- Function to check the notification count
local function check_notifications()
	local sql = [[select count(*) as cnt from record where style=1 and presented=false OR style=2;]]
	local cmd = string.format("sqlite3 -readonly '%s' \"%s\"", notif_db, sql)

	sbar.exec(cmd, function(output)
		local count = tonumber(output) or 0
		if count > 0 then
			notifications:set({
				icon = { string = "●" },
				label = { string = tostring(count) },
			})
		else
			notifications:set({
				icon = { string = "" },
				label = { string = "" },
			})
		end
	end)
end

notifications:subscribe({ "forced", "routine", "system_woke" }, function()
	check_notifications()
end)

notifications:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec("cliclick kd:fn t:n")
	end
end)

-- Initial run
check_notifications()
