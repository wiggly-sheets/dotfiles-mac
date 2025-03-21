local colors    = require("colors")
local settings  = require("settings")
local app_icons = require("helpers.app_icons")

local front_app = sbar.add("item", "front_app", {
  display = "active",
  -- Initialize the icon area (hidden until an app is active)
  icon = {
    drawing = false,
    font = "sketchybar-app-font:Regular:16.0",  -- Ensure this is your icon font
    string = "",
    padding_right = 5,
    padding_left = 0,
    color = colors.magenta,  -- Set icon color to magenta
  },
  label = {
    font = {
      style = settings.font.style_map["Black"],
      size = 12.0,
    },
    background = {
      color = colors.magenta,
      border_width = 1,
      height = 26,
      border_color = colors.black,
    },
    string = "",
  },
  updates = true,
})

front_app:subscribe("front_app_switched", function(env)
  -- env.INFO is assumed to be the app name (e.g., "Safari")
  local app = env.INFO
  -- Look up the icon for the app; fall back to "Default" if none is found.
  local icon = app_icons[app] or app_icons["Default"]

  front_app:set({
    -- Enable icon drawing and set the proper icon font, string, and color
    icon = {
      drawing = true,
      string = icon,
      font = "sketchybar-app-font:Regular:16.0",  -- Must be an icon-supporting font
      padding_right = 5,
      color = colors.magenta,  -- Set icon color to magenta
    },
    -- Set the app name as the label
    label = {
      string = app,
    },
  })
end)

front_app:subscribe("mouse.clicked", function(env)
  sbar.trigger("swap_menus_and_spaces")
end)
