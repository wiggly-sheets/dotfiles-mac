--------------------------------------------------------
--                    MPD ITEM
--------------------------------------------------------

local mpd = sbar.add("item", "mpd", {
	icon = {
		string = "",
		font = settings.default,
		padding_right = 5,
	},
	label = {
		string = "",
		font = settings.default,
		max_chars = 20,
		scroll_texts = true,
		scroll_duration = 200,
	},
	updates = "when_shown",
	update_freq = 2,
	position = "left",
	popup = { align = "center", horizontal = true },
})

-- MPD Popup Controls
local back = sbar.add("item", "back", {
	position = "popup." .. mpd.name,
	icon = {
		string = icons.media.back,
		padding_left = 5,
	},
	click_script = "mpc prev",
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

-- Popup Song Info for MPD
local mpd_info = sbar.add("item", "mpd_info", {
	position = "popup." .. mpd.name,
	icon = { drawing = false },
	label = {
		string = "",
		font = settings.default,
		width = "dynamic",
		align = "center",
		padding_right = 5,
	},
})

-- Store last track info globally
local last_artist, last_album, last_song = "", "", ""

local function update_mpd()
	sbar.exec("mpc status", function(status)
		if status and status:match("playing") then
			sbar.exec("mpc current -f %artist%", function(artist)
				last_artist = artist or ""
				sbar.exec("mpc current -f %album%", function(album)
					last_album = album or ""
					sbar.exec("mpc current -f %title%", function(song)
						last_song = song or ""
						local text = last_artist .. "   " .. last_album .. "   " .. last_song
						mpd:set({
							label = { string = text, drawing = true },
							icon = { string = "", font = { size = 10 } },
						})
						sbar.set("mpd_info", { label = { string = text } })
					end)
				end)
			end)
		elseif status and status:match("paused") then
			local text = last_artist .. "   " .. last_album .. "   " .. last_song
			mpd:set({
				icon = { string = "", font = { size = 10 }, color = colors.grey },
				label = { string = text, drawing = true, color = colors.grey },
			})
			sbar.set("mpd_info", { label = { string = text } })
		else
			mpd:set({
				icon = { string = "", font = { size = 10 } },
				label = { string = "" },
			})
			sbar.set("mpd_info", { label = { string = "" } })
			last_artist, last_album, last_song = "", "", ""
		end
	end)
end

mpd:subscribe("routine", update_mpd)

mpd:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		mpd:set({ popup = { drawing = "toggle" } })
	elseif env.BUTTON == "right" then
		sbar.exec("mpc toggle")
	else
		sbar.exec("mpc stop")
	end
end)

mpd:subscribe("mouse.exited.global", "mouse.exited", function()
	mpd:set({ popup = { drawing = false } })
end)

-- ======== Hover effects ========
local function add_hover(item)
	item:subscribe("mouse.entered", function()
		item:set({
			background = {
				drawing = true,
				color = 0x40FFFFFF,
				corner_radius = 20,
				height = 20,
				x_offset = 0,
			},
		})
	end)

	item:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
		item:set({ background = { drawing = false } })
	end)
end

add_hover(mpd)

update_mpd()
