local icons = require("icons")

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
	updates = "when_shown",
	update_freq = 2,
	position = "left",
	popup = { align = "center", horizontal = true },
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
							label = {
								string = artist .. "  " .. album .. "  " .. song,
								drawing = true,
							},
							icon = { string = "", font = { size = 20 } },
						})
					end)
				end)
			end)
		end
	end)
end

local back = sbar.add("item", "back", {

	position = "popup." .. mpd.name,
	icon = { string = icons.media.back },
	click_script = "mpc next",
})

local play_pause = sbar.add("item", "play_pause", {

	position = "popup." .. mpd.name,

	icon = { string = icons.media.play_pause },

	click_script = "mpc toggle",
})

local forward = sbar.add("item", "forward", {

	position = "popup." .. mpd.name,
	icon = { string = icons.media.forward },
	click_script = "mpc next",
})

mpd:subscribe("routine", update_mpd)

-- Popup toggle on click
mpd:subscribe("mouse.clicked", function()
	mpd:set({ popup = { drawing = "toggle" } })
end)

mpd:subscribe("mouse.exited.global", function()
	mpd:set({ popup = { drawing = false } })
end)

update_mpd()
