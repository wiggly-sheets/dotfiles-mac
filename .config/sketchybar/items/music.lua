--====================================================--
--  MPD + Media Items Combined for SketchyBar
--====================================================--

local icons = require("icons")
local settings = require("settings")

--------------------------------------------------------
--                    MEDIA ITEM
--------------------------------------------------------

local media = sbar.add("item", "media", {
	position = "left",
	update_freq = 2,
	padding_right = 5,
	padding_left = 5,
	label = {
		string = "",
		font = settings.default,
		max_chars = 15,
		scroll_texts = true,
		scroll_duration = 200,
	},
	icon = {
		string = "",
		font = { size = 20 },
		padding_right = 5,
	},
	updates = "when_shown",
	popup = { align = "center", horizontal = true },
})

-- Media Popup Controls
sbar.add("item", {
	position = "popup." .. media.name,
	icon = { string = icons.media.back },
	label = { drawing = false },
	click_script = "media-control previous-track",
})
sbar.add("item", {
	position = "popup." .. media.name,
	icon = { string = icons.media.play_pause },
	label = { drawing = false },
	click_script = "media-control toggle-play-pause",
})
sbar.add("item", {
	position = "popup." .. media.name,
	icon = { string = icons.media.forward },
	label = { drawing = false },
	click_script = "media-control next-track",
})

-- Helper to clean jq output
local function clean(output)
	if not output then
		return ""
	end
	output = output:gsub("^%s+", ""):gsub("%s+$", "")
	if output == "null" or output == "nil" or output == "" then
		return ""
	end
	return output
end

-- Update routine
local function update_media()
	local artist, album, song = "", "", ""

	-- Fetch each field sequentially
	sbar.exec("media-control get | jq -r '.artist'", function(a)
		artist = clean(a)
		sbar.exec("media-control get | jq -r '.album'", function(al)
			album = clean(al)
			sbar.exec("media-control get | jq -r '.title'", function(t)
				song = clean(t)

				-- Determine state
				if artist == "" and album == "" and song == "" then
					-- stopped / no player
					media:set({
						icon = { string = "", font = settings.default, drawing = true },
						label = { string = "", drawing = true },
					})
				else
					-- Check if player is paused
					sbar.exec("media-control get | jq -r '.playing'", function(p)
						p = clean(p)
						if p == "false" then
							-- paused
							media:set({
								icon = { string = "􀊅", font = settings.default, drawing = true },
								label = {
									string = artist .. "  " .. album .. "  " .. song,
									drawing = true,
								},
							})
						else
							-- playing
							media:set({
								icon = { string = "", font = settings.default, drawing = true },
								label = { string = artist .. "  " .. album .. "  " .. song, drawing = true },
							})
						end
					end)
				end
			end)
		end)
	end)
end

-- Subscribe to routine updates
media:subscribe("routine", update_media)

-- Click logic
media:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		media:set({ popup = { drawing = "toggle" } })
	elseif env.BUTTON == "right" then
		sbar.exec("media-control toggle-play-pause")
	else
		sbar.exec("media-control stop")
	end
end)

media:subscribe("mouse.exited.global", "mouse.exited", function()
	media:set({ popup = { drawing = false } })
end)

-- Initial update
update_media()

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
		max_chars = 15,
		scroll_texts = true,
		scroll_duration = 200,
	},
	updates = "when_shown",
	update_freq = 2,
	position = "left",
	popup = { align = "center", horizontal = true },
})
-- Store last track info globally (or at least within this module)
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
						mpd:set({
							label = {
								string = last_artist .. "  " .. last_album .. "  " .. last_song,
								drawing = true,
							},
							icon = { string = "", font = { size = 20 } },
						})
					end)
				end)
			end)
		elseif status and status:match("paused") then
			-- Use last stored track info
			mpd:set({
				icon = { string = "􀊅", font = { size = 20 } },
				label = {
					string = last_artist .. "  " .. last_album .. "  " .. last_song,
					drawing = true,
				},
			})
		else
			mpd:set({
				icon = { string = "", font = { size = 20 } },
				label = { string = "" },
			})
			-- Clear stored info when stopped
			last_artist, last_album, last_song = "", "", ""
		end
	end)
end

-- MPD Popup Controls
local back = sbar.add("item", "back", {
	position = "popup." .. mpd.name,
	icon = { string = icons.media.back },
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

update_mpd()
