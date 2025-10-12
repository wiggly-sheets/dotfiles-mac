--====================================================--
--  MPD + Media Items Combined for SketchyBar
--====================================================--

local icons = require("icons")
local settings = require("settings")

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
		if status and status:match("playing") then
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
		elseif status and status:match("paused") then
			mpd:set({
				icon = { string = "􀊅", font = { size = 20 } },
				label = { string = "" },
			})
		else
			mpd:set({
				icon = { string = "", font = { size = 20 } },
				label = { string = "" },
			})
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

--------------------------------------------------------
--                    MEDIA ITEM
--------------------------------------------------------

local media = sbar.add("item", "media", {
	position = "right",
	update_freq = 2,
	padding_right = 5,
	padding_left = 2,
	label = {
		string = "",
		font = "Inconsolata Nerd Font Mono",
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
	popup = { align = "right", horizontal = true },
})

-- Media Popup Controls
sbar.add("item", {
	position = "popup." .. media.name,
	icon = { string = icons.media.back },
	label = { drawing = false },
	click_script = "media-control previous_track",
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

-- Cleanup helper
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

-- Media Update Routine
local function update_media()
	sbar.exec("media-control get | jq -r '.status'", function(status)
		status = clean(status)

		if status == "playing" then
			sbar.exec("media-control get | jq -r '.artist'", function(artist)
				sbar.exec("media-control get | jq -r '.album'", function(album)
					sbar.exec("media-control get | jq -r '.title'", function(song)
						local artist_clean = clean(artist)
						local album_clean = clean(album)
						local song_clean = clean(song)
						local label_text = artist_clean .. "  " .. album_clean .. "  " .. song_clean
						media:set({
							icon = { string = "", font = { size = 20 } },
							label = { string = label_text, drawing = true },
						})
					end)
				end)
			end)
		elseif status == "paused" then
			media:set({
				icon = { string = "􀊅", font = { size = 20 } },
				label = { string = "" },
			})
		else
			media:set({
				icon = { string = "", font = { size = 20 } },
				label = { string = "" },
			})
		end
	end)
end

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

update_media()
