local colors = require("colors")
local icons = require("icons")
local json = require("dkjson")

-- Only track whitelisted apps
local whitelist = {
	["Chromatix"] = true,
	["Podcasts"] = true,
	["Zen"] = false,
}

-- Media cover in the bar (small icon)
local media_cover = sbar.add("item", "media_cover", {
	position = "right",
	update_freq = 5,
	label = { drawing = false },
	icon = {
		drawing = true,
		string = "􀑪",
		font = { size = 14 },
	},
	background = { color = colors.transparent },
	updates = true,
	popup = { align = "center", horizontal = true },
})

-- Popup items
local media_artist = sbar.add("item", {
	position = "popup." .. media_cover.name,
	label = { font = { size = 10 }, color = colors.white, max_chars = 18, width = 0 },
	icon = { drawing = false },
})
local media_title = sbar.add("item", {
	position = "popup." .. media_cover.name,
	label = { font = { size = 12 }, color = colors.white, max_chars = 24, width = 0 },
	icon = { drawing = false },
})

-- Media controls in popup
sbar.add("item", {
	position = "popup." .. media_cover.name,
	icon = { string = icons.media.back },
	label = { drawing = false },
	click_script = "media-control previous_track",
})
sbar.add("item", {
	position = "popup." .. media_cover.name,
	icon = { string = icons.media.play_pause },
	label = { drawing = false },
	click_script = "media-control toggle-play-pause",
})
sbar.add("item", {
	position = "popup." .. media_cover.name,
	icon = { string = icons.media.forward },
	label = { drawing = false },
	click_script = "media-control next-track",
})

-- Helper to animate popup width
local function animate_popup_width(width)
	sbar.animate("tanh", 20.0, function()
		media_artist:set({ label = { width = width } })
		media_title:set({ label = { width = width } })
	end)
end

local interrupt = 0
local function show_popup(visible)
	if not visible then
		interrupt = interrupt - 1
	end
	if interrupt > 0 and not visible then
		return
	end
	local target_width = visible and "dynamic" or 0
	animate_popup_width(target_width)
end

-- Routine updates
media_cover:subscribe("routine", function()
	sbar.exec("mediacontrol get -h json", function(json_output)
		local data, pos, err = json.decode(json_output)
		if not data then
			media_cover:set({ drawing = true }) -- minimal icon only
			media_artist:set({ drawing = false })
			media_title:set({ drawing = false })
			return
		end

		local app = data.bundleIdentifier:match("com%.([^.]+)") or "Unknown"

		if whitelist[app] and data.playing then
			media_artist:set({ drawing = true, label = data.artist ~= "" and data.artist or "Unknown Artist" })
			media_title:set({ drawing = true, label = data.title ~= "" and data.title or "Unknown Title" })
		else
			media_artist:set({ drawing = false })
			media_title:set({ drawing = false })
		end
	end)
end)

-- Popup toggle on click
media_cover:subscribe("mouse.clicked", function()
	media_cover:set({ popup = { drawing = "toggle" } })
end)

-- Animate popup on hover
media_cover:subscribe("mouse.entered", function()
	interrupt = interrupt + 1
	show_popup(true)
end)
media_cover:subscribe("mouse.exited", function()
	show_popup(false)
end)
media_title:subscribe("mouse.exited.global", function()
	media_cover:set({ popup = { drawing = false } })
end)
