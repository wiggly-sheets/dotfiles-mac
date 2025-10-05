local mpd = sbar.add("item", "mpd", {
	icon = {
		string = "",
		font = "Inconsolata Nerd Font Mono",
	},
	label = {
		string = "",
		font = "Inconsolata Nerd Font Mono",
	},
	updates = true,
	update_freq = 5,
	position = "left",
})

local function update_mpd()
	sbar.exec("mpc status | wc -l | tr -d ' '", function(line_count)
		if tonumber(line_count) == 1 then
			-- No song playing
			mpd:set({
				icon = { string = "" },
				label = { string = "" },
			})
		else
			sbar.exec("mpc current -f %artist%", function(artist)
				sbar.exec("mpc current -f %title%", function(song)
					sbar.exec("mpc current state", function(status)
						local icon
						if status ~= "playing" then
							icon = "􀊖" -- playing
						else
							icon = "􀊘" -- paused
						end
						local output = artist:gsub("\n", "") .. " • " .. song:gsub("\n", "")
						mpd:set({
							icon = { string = icon, drawing = true },
							label = { string = output, drawing = true },
						})
					end)
				end)
			end)
		end
	end)
end

mpd:subscribe("routine", update_mpd)
update_mpd()
