local icons = require("icons")

-- Media cover in the bar (small icon)
local media = sbar.add("item", "media", {
	position = "right",
	update_freq = 2,
	padding_right = 2,
	padding_left = 2,
	label = { drawing = true },
	icon = {
		drawing = true,
		string = "",
		font = { size = 25 },
	},
	updates = "when_shown",
	popup = { align = "right", horizontal = true },
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
local artist = ""
local album = ""
local song = ""

local function clean(output)
	if not output then
		return ""
	end
	output = output:gsub("^%s+", ""):gsub("%s+$", "") -- trim whitespace
	if output == "null" or output == "nil" or output == "" then
		return ""
	end
	return output
end

-- Routine to update playing status first
media:subscribe("routine", function()
	-- 1. Check playing(
	sbar.exec("media-control get | jq -r '.artist'", function(output)
		artist = output
	end)

	-- 3. Fetch album
	sbar.exec("media-control get | jq -r '.album'", function(output)
		album = output
	end)

	-- 4. Fetch title
	sbar.exec("media-control get | jq -r '.title'", function(output)
		song = output
	end)
end)

local artist_popup = sbar.add("item", "artist_popup", {
	position = "popup.media",
	label = { drawing = true },
})

local album_popup = sbar.add("item", "album_popup", {
	position = "popup.media",
	label = {
		drawing = true,
	},
})

local title_popup = sbar.add("item", "song_popup", {
	position = "popup.media",
	label = {
		drawing = true,
	},
})

media:subscribe("routine", function()
	sbar.exec(
		"media-control get | jq -r '.artist'",
		function(output)
			artist = clean(output)
			artist_popup:set({ label = { string = "Artist: " .. artist }, drawing = true })
		end,

		sbar.exec("media-control get | jq -r '.album'", function(output)
			album = clean(output)
			album_popup:set({ label = { string = "Album: " .. album }, drawing = true })
		end),

		sbar.exec("media-control get | jq -r '.title'", function(output)
			song = clean(output)
			title_popup:set({ label = { string = "Song: " .. song }, drawing = true })
		end)
	)
end)

-- Popup toggle on click
media:subscribe(
	"mouse.clicked",
	function(env)
		if env.BUTTON == "left" then
			media:set({ popup = { drawing = "toggle" } })
		else
			sbar.exec("media-control toggle-play-pause")
		end
	end,

	media:subscribe("mouse.exited.global", "mouse.exited", function()
		media:set({ popup = { drawing = false } })
	end)
)
