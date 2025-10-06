local colors = require("colors")

-- Add an item for notifications
local notifications = sbar.add("item", "widgets.notifications", {
	position = "right",
	y_offset = 10,
	padding_left = -20,
	icon = {
		font = { family = "JetBrainsMono Nerd Font", style = "Regular", size = 12 },
		color = colors.red,
	},
	label = {
		string = "",
		font = { family = "JetBrainsMono Nerd Font", style = "Bold", size = 10 },
	},
	update_freq = 60,
})

local function update_notifications()
	-- the shell command
	local cmd = [[
        sql="select count(*) as cnt from record where style=1 and presented=false OR style=2;"
        sqlite3 -readonly ~/Library/Group\ Containers/group.com.apple.usernoted/db2/db "$sql"
    ]]

	sbar.exec(cmd, function(output)
		local count = tonumber(output) or 0
		if count > 0 then
			notifications:set({
				icon = { string = "●" }, -- red dot
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

notifications:subscribe({ "routine", "forced", "system_woke" }, update_notifications)
update_notifications()
