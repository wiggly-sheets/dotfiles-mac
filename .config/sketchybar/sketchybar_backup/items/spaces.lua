local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}

for i = 1, 10, 1 do
  local space = sbar.add("space", "space." .. i, {
    space = i,
    icon = {
      font = { family = settings.font.numbers },
      string = i,
      padding_left = 8,
      padding_right = 8,
      color = colors.red,
      highlight_color = colors.green,
    },
    label = {
      padding_right = 10,
      color = colors.red,
      highlight_color = colors.white,
      font = "sketchybar-app-font:Regular:16.0",
      y_offset = -1,
    },
    padding_right = 1,
    padding_left = 1,
    background = {
      color = colors.bg3,
      border_width = 1,
      height = 26,
      border_color = colors.black,
    },
    popup = { background = { border_width = 5, border_color = colors.black } }
  })

  spaces[i] = space

  local space_bracket = sbar.add("bracket", { space.name }, {
    background = {
      color = colors.transparent,
      border_color = colors.bg2,
      height = 28,
      border_width = 2
    }
  })

  sbar.add("space", "space.padding." .. i, {
    space = i,
    script = "",
    width = settings.group_paddings,
  })

  local space_popup = sbar.add("item", {
    position = "popup." .. space.name,
    padding_left = 5,
    padding_right = 0,
    background = {
      drawing = true,
      image = {
        corner_radius = 9,
        scale = 0.2
      }
    }
  })

  space:subscribe("space_change", function(env)
    local selected = env.SELECTED == "true"
    space:set({
      icon = { highlight = selected },
      label = { highlight = selected },
      background = { border_color = selected and colors.black or colors.bg2 }
    })
    space_bracket:set({
      background = { border_color = selected and colors.green or colors.bg2 }
    })
  end)

  space:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "other" then
      space_popup:set({ background = { image = "space." .. env.SID } })
      space:set({ popup = { drawing = "toggle" } })
    else
      local op = (env.BUTTON == "right") and "--destroy" or "--focus"
      sbar.exec("yabai -m space " .. op .. " " .. env.SID)
    end
  end)

  space:subscribe("mouse.exited", function(_)
    space:set({ popup = { drawing = false } })
  end)
end

local space_app_icons = {}
for i = 1, 10 do
  space_app_icons[i] = "—"
end

local space_window_observer = sbar.add("item", {
  drawing = false,
  updates = true,
})

local spaces_indicator = sbar.add("item", {
  padding_left = 8,
  padding_right = 8,
  icon = {
    padding_left = 10,
    padding_right = 10,
    color = colors.blue,
    string = "←",
    font = { size = 18, bold = true },
  },
  background = {
    color = colors.transparent,
    border_width = 0,
  }
})

spaces_indicator:subscribe("mouse.entered", function(env)
  sbar.animate("ease_in_out", 20, function()
    spaces_indicator:set({
      icon = { color = colors.green },
      background = { color = colors.black }
    })
  end)
end)

spaces_indicator:subscribe("mouse.exited", function(env)
  sbar.animate("ease_in_out", 20, function()
    spaces_indicator:set({
      icon = { color = colors.blue },
      background = { color = colors.transparent }
    })
  end)
end)

spaces_indicator:subscribe("mouse.clicked", function(env)
  local current_icon = spaces_indicator:query().icon["string"]
  local new_icon = (current_icon == "←") and "→" or "←"
  
  spaces_indicator:set({
    icon = { string = new_icon, color = colors.green }
  })
  
  sbar.trigger("swap_menus_and_spaces")
end)

space_window_observer:subscribe("space_windows_change", function(env)
  local sid = env.INFO.space
  local icon_line = ""
  local no_app = true

  for app, count in pairs(env.INFO.apps) do
    no_app = false
    local lookup = app_icons[app]
    local icon = ((lookup == nil) and app_icons["Default"] or lookup)
    icon_line = icon_line .. icon
  end

  if no_app then
    icon_line = "—"
  end

  space_app_icons[sid] = icon_line

  for space_id, space in ipairs(spaces) do
    sbar.animate("tanh", 10, function()
      space:set({ label = space_app_icons[space_id] })
    end)
  end
end)
