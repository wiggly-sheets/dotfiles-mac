local colors = require("colors")
local icons = require("icons")

-- Only track whitelisted apps
local whitelist = {
	["Chromatix"] = true,
	["Podcasts"] = true,
	["Zen"] = true,
}

-- Media cover in the bar (small icon)
local media = sbar.add("item", "media", {
	position = "right",
	update_freq = 5,
	label = { drawing = true },
	icon = {
		drawing = true,
		string = "",
		font = { size = 25 },
	},
	updates = true,
	popup = { align = "center", horizontal = true },
})

-- Popup items
local media_artist = sbar.add("item", {
	position = "popup." .. media.name,
	label = { font = { size = 10 }, color = colors.white, max_chars = 18, width = 0 },
	icon = { drawing = false },
})
local media_title = sbar.add("item", {
	position = "popup." .. media.name,
	label = { font = { size = 12 }, color = colors.white, max_chars = 24, width = 0 },
	icon = { drawing = false },
})

-- Media controls in popup
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

-- State variables to hold current media info
local playing = false
local artist = ""
local album = ""
local title = ""

-- Routine to update playing status first
media:subscribe("routine", function()
	-- 1. Check playing
	sbar.exec("media-control get | jq -r '.playing'", function(output)
		playing = output == "true"

		if playing then
			-- 2. Fetch artist
			sbar.exec("media-control get | jq -r '.artist // \"Unknown Artist\"'", function(output)
				artist = output
			end)

			-- 3. Fetch album
			sbar.exec("media-control get | jq -r '.album // \"Unknown Album\"'", function(output)
				album = output
			end)

			-- 4. Fetch title
			sbar.exec("media-control get | jq -r '.title // \"Unknown Title\"'", function(output)
				title = output
			end)
		else
			artist = ""
			album = ""
			title = ""
		end
	end)
end)

local artist_popup = sbar.add("item", "artist_popup", {
	position = "popup.media",
	label = { string = "Artist: " .. artist },
})

local album_popup = sbar.add("item", "album_popup", {
	position = "popup.media",
	label = { string = "Album: " .. album },
})

local title_popup = sbar.add("item", "title_popup", {
	position = "popup.media",
	label = { string = "Title: " .. title },
})
-- Popup toggle on click
media:subscribe("mouse.clicked", function()
	media:set({ popup = { drawing = "toggle" } })
end)

media_title:subscribe("mouse.exited.global", function()
	media:set({ popup = { drawing = "toggle" } })
end)
