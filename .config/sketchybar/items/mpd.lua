local colors = require("colors")
local icons = require("icons")

-- Add the MPD item (default hidden)
local mpd_item = sbar.add("item", "mpd", {
	position = "right",
	icon = {
		drawing = false, -- hidden by default
		string = "",
		font = { size = 14 },
		color = colors.yellow,
	},
	label = {
		drawing = false, -- hidden by default
		string = "",
		font = { family = "Inconsolata Nerd Font Mono", size = 12 },
		color = colors.white,
	},
	padding_right = 10,
	update_freq = 5,
})

-- Function to update MPD status
local function update_mpd()
	sbar.exec("mpc status | wc -l | tr -d ' '", function(line_count)
		line_count = line_count:gsub("\n", "")
		if line_count == "1" then
			-- Nothing playing: hide icon/label
			mpd_item:set({
				icon = { drawing = false },
				label = { drawing = false },
			})
		else
			-- Something is playing: show icon/label
			sbar.exec("mpc current -f '%artist%•%title%•%state%'", function(result)
				result = result:gsub("\n", "")
				local artist, title, status = result:match("^(.-)•(.-)•(.-)$")
				if artist and title and status then
					local icon = status == "playing" and "" or ""
					local label = artist .. " • " .. title
					mpd_item:set({
						icon = { string = icon, drawing = true },
						label = { string = label, drawing = true },
					})
				end
			end)
		end
	end)
end

-- Subscribe to routine updates
mpd_item:subscribe({ "routine" }, update_mpd)

-- Initialize on startup
update_mpd()
