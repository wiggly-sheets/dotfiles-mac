local mpd = sbar.add("item", "mpd", {
	icon = {
		string = "",
		font = "Inconsolata Nerd Font Mono",
		padding_right = 5,
	},
	label = {
		string = "",
		font = "Inconsolata Nerd Font Mono",
		max_chars = 15,
		scroll_texts = true,
		scroll_duration = 200,
	},
	updates = true,
	update_freq = 5,
	position = "left",
	click_script = "mpc toggle",
})

local function update_mpd()
	sbar.exec("mpc status", function(status)
		if status and status:match("paused") then
			-- No song playing
			mpd:set({
				icon = { string = "􀊅", font = { size = 20 } },
				label = { string = "" },
			})
		else
			sbar.exec("mpc current -f %artist%", function(artist)
				sbar.exec("mpc current -f %album%", function(album)
					sbar.exec("mpc current -f %title%", function(song)
						mpd:set({
							label = { string = artist .. "  " .. album .. "  " .. song, drawing = true },
							icon = { string = "", font = { size = 20 } },
						})
					end)
				end)
			end)
		end
	end)
end

mpd:subscribe("routine", update_mpd)

update_mpd()
