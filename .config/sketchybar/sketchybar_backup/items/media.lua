local icons = require("icons")
local colors = require("colors")

local whitelist = { ["Spotify"] = true, ["Music"] = true }

--------------------------------------------------
-- MAIN WIDGET (ALWAYS VISIBLE)
--------------------------------------------------
local media_cover = sbar.add("item", {
  name = "media_cover",
  position = "right",
  background = {
    image = { string = "", scale = 0 },
    color = colors.transparent,
  },
  label = { drawing = false },
  icon = { drawing = true, string = icons.music },  -- Shows SF music icon when no media is playing
  drawing = true,
  updates = true,
  popup = {
    align = "center",
    horizontal = false,  -- Stack popup items vertically
    width = "dynamic",   -- Adjust width based on content
    drawing = false,     -- Initially hidden
  }
})

--------------------------------------------------
-- POPUP ITEMS (ARTIST, ALBUM, TITLE, SCROLLING TEXT)
--------------------------------------------------
-- 1. Artist (Top)
local popup_artist = sbar.add("item", {
  name = "popup_artist",
  position = "popup." .. media_cover.name,
  icon = { drawing = false },
  label = {
    font = { size = 11 },
    color = colors.with_alpha(colors.white, 0.7),
    max_chars = 24,
  },
  drawing = false,  -- Enabled when media info is available
  width = "dynamic",  -- Allow dynamic width
  scroll_texts = true,  -- Enable scrolling for long names
})

-- 2. Album (Middle)
local popup_album = sbar.add("item", {
  name = "popup_album",
  position = "popup." .. media_cover.name,
  icon = { drawing = false },
  label = {
    font = { size = 11 },
    color = colors.with_alpha(colors.white, 0.5),
    max_chars = 24,  -- You can adjust this if needed
  },
  drawing = false,
  width = "dynamic",  -- Allow dynamic width
  scroll_texts = true,  -- Enable scrolling for long album names
})

-- 3. Song Title (Bottom)
local popup_title = sbar.add("item", {
  name = "popup_title",
  position = "popup." .. media_cover.name,
  icon = { drawing = false },
  label = {
    font = { size = 12, weight = "bold" },
    color = colors.white,
    max_chars = 24,
  },
  drawing = false,
  width = "199",  -- Allow dynamic width
  scroll_texts = true,  -- Enable scrolling for long song titles
})

--------------------------------------------------
-- PLAYBACK CONTROLS (HORIZONTAL ALIGNMENT)
--------------------------------------------------
-- 4a. Playback Control: Previous
local popup_previous = sbar.add("item", {
  name = "popup_previous",
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.back },
  label = { drawing = false },
  click_script = "nowplaying-cli previous",
})

-- 4b. Playback Control: Play/Pause
local popup_play_pause = sbar.add("item", {
  name = "popup_play_pause",
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.play, width = 18 },
  label = { drawing = false },
  click_script = "nowplaying-cli togglePlayPause",
})

-- 4c. Playback Control: Next
local popup_next = sbar.add("item", {
  name = "popup_next",
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.forward },
  label = { drawing = false },
  click_script = "nowplaying-cli next",
})

--------------------------------------------------
-- GROUP THE CONTROLS INTO A HORIZONTAL ROW
--------------------------------------------------
local playback_controls_row = sbar.add("item", {
  position = "popup." .. media_cover.name,
  label = { drawing = false },
  popup = {
    horizontal = true,  -- Align controls in a row
    width = "dynamic",  -- Allow dynamic width for the entire row
  },
})

--------------------------------------------------
-- UPDATE FUNCTION: REFRESH THE WIDGET & POPUP INFO
--------------------------------------------------
local function update_widget(env)
  if env and env.INFO and whitelist[env.INFO.app] then
    local is_playing = (env.INFO.state == "playing")
    local is_paused  = (env.INFO.state == "paused")

    -- Update the popup text items with media info
    popup_artist:set({ label = env.INFO.artist or "Unknown Artist", drawing = true })
    popup_album:set({ label = env.INFO.album or "Unknown Album", drawing = true })
    popup_title:set({ label = env.INFO.title or "Unknown Title", drawing = true })

    if is_playing or is_paused then
      -- When media is playing or paused, show album artwork on the main widget
      media_cover:set({
        background = { image = { string = "media.artwork", scale = 0.85 } },
        icon = { drawing = false },
      })
      popup_play_pause:set({ icon = { string = is_playing and icons.media.pause or icons.media.play } })
    else
      -- When media is stopped, show the SF music icon
      media_cover:set({
        background = { image = { string = "", scale = 0 } },
        icon = { drawing = true, string = icons.music },
      })
      popup_play_pause:set({ icon = { string = icons.media.play } })
    end
  else
    -- For non-whitelisted apps or missing media info, show default info
    media_cover:set({
      background = { image = { string = "", scale = 0 } },
      icon = { drawing = true, string = icons.music },
    })
    popup_artist:set({ label = "No Media Playing", drawing = true })
    popup_album:set({ label = "", drawing = false })
    popup_title:set({ label = "", drawing = false })
  end
end

media_cover:subscribe("media_change", update_widget)

--------------------------------------------------
-- INTERACTION: TOGGLE THE POPUP ON CLICK & HIDE ON MOUSE EXIT
--------------------------------------------------
media_cover:subscribe("mouse.clicked", function(env)
  media_cover:set({ popup = { drawing = "toggle" } })
end)

media_cover:subscribe("mouse.exited.global", function(env)
  media_cover:set({ popup = { drawing = false } })
end)
