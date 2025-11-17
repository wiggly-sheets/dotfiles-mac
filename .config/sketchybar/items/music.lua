local icons = require("icons")
local settings = require("settings")
local colors = require("colors")

-- Whitelist apps by bundleIdentifier
local allowed_bundle_ids = {
	["com.colliderli.iina"] = true,
	["com.chromatix.app"] = true,
	["com.apple.Podcasts"] = true,
	["com.highcaffeinecontent.radio"] = true,
}

local media = sbar.add("item", "media", {
	position = "left",
	update_freq = 2,
	padding_right = 5,
	padding_left = 5,
	label = {
		string = "",
		font = { family = settings.default, size = 10 },
		max_chars = 20,
		scroll_texts = true,
		scroll_duration = 200,
	},
	icon = {
		string = "",
		font = { size = 12 },
		padding_right = 5,
	},
	updates = "when_shown",
	popup = { align = "center", horizontal = true },
})

-- Popup Controls
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

local media_info = sbar.add("item", "media_info", {
	position = "popup." .. media.name,
	icon = { drawing = false },
	label = { string = "", font = settings.default, width = "dynamic", align = "center" },
})

local function clean(str)
	if not str then
		return ""
	end
	str = str:gsub("^%s+", ""):gsub("%s+$", "")
	return (str == "null" or str == "nil") and "" or str
end

local function update_media()
	-- Get bundleIdentifier first
	sbar.exec("media-control get | jq -r '.bundleIdentifier'", function(bundle_id)
		bundle_id = clean(bundle_id)

		-- Hide widget if app is not whitelisted
		if not allowed_bundle_ids[bundle_id] then
			media:set({ icon = { drawing = false }, label = { drawing = false } })
			sbar.set("media_info", { label = { string = "" } })
			return
		end

		-- Fetch artist, album, song
		local artist, album, song = "", "", ""
		sbar.exec("media-control get | jq -r '.artist'", function(a)
			artist = clean(a)
			sbar.exec("media-control get | jq -r '.album'", function(al)
				album = clean(al)
				sbar.exec("media-control get | jq -r '.title'", function(t)
					song = clean(t)
					if artist == "" and album == "" and song == "" then
						media:set({ icon = { string = "", drawing = false }, label = { string = "", drawing = false } })
						sbar.set("media_info", { label = { string = "" } })
					else
						sbar.exec("media-control get | jq -r '.playing'", function(p)
							p = clean(p)
							local text = artist .. "  " .. album .. "  " .. song
							if p == "false" then
								media:set({
									icon = {
										string = "",
										font = settings.default,
										drawing = true,
										color = colors.grey,
									},
									label = { string = text, drawing = true, color = colors.grey },
								})
							else
								media:set({
									icon = {
										string = "",
										font = settings.default,
										drawing = true,
										color = colors.white,
									},
									label = { string = text, drawing = true, color = colors.white },
								})
							end
							sbar.set("media_info", { label = { string = text } })
						end)
					end
				end)
			end)
		end)
	end)
end

media:subscribe("routine", update_media)

-- Mouse clicks
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

-- Popup Song Info for MPD
local mpd_info = sbar.add("item", "mpd_info", {
	position = "popup." .. mpd.name,
	icon = { drawing = false },
	label = {
		string = "",
		font = settings.default,
		width = "dynamic",
		align = "center",
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
						local text = last_artist .. "  " .. last_album .. "  " .. last_song
						mpd:set({
							label = { string = text, drawing = true },
							icon = { string = "", font = { size = 10 } },
						})
						sbar.set("mpd_info", { label = { string = text } })
					end)
				end)
			end)
		elseif status and status:match("paused") then
			local text = last_artist .. "  " .. last_album .. "  " .. last_song
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

update_mpd()
