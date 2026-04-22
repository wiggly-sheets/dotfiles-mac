local colors = require("colors")
local settings = require("default")
local icons = require("icons")

-- Path to macOS Notification Center database
local notif_db = os.getenv("HOME") .. "/Library/Group Containers/group.com.apple.usernoted/db2/db"

-- Create the SketchyBar item
local notifications = sbar.add("item", "notifications", {
	position = "right",
	width = 5,
	y_offset = 8,
	padding_right = 18,

	icon = {
		padding_right = 0,
		padding_left = 0,
		string = "",
		color = colors.notifications,
		font = { family = settings.default, size = 18 },
	},
	label = {
		string = "",
		font = { family = settings.default, style = "Bold", size = 8.5 },
		color = colors.white,
	},
	update_freq = 30,
})

-- Function to check the notification count
local function check_notifications()
	local sql = [[select count(*) as cnt from record where style=1 and presented=false OR style=2;]]
	local cmd = string.format("sqlite3 -readonly '%s' \"%s\"", notif_db, sql)
	sbar.exec(cmd, function(output)
		local count = math.max((tonumber(output) or 0) - 1, 0)

		if count > 9 then
			notifications:set({
				icon = { string = icons.notifications },
				label = { string = "9+", padding_left = -12 },
			})
		else
			if count > 0 then
				notifications:set({
					icon = { string = icons.notifications },
					label = { string = tostring(count), padding_left = -9 },
				})
			else
				notifications:set({
					icon = { string = "" },
					label = { string = "" },
				})
			end
		end
	end)
end

notifications:subscribe({ "forced", "routine", "system_woke" }, function()
	check_notifications()
end)

-- Initial run
check_notifications()
