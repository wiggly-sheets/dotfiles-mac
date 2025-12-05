local theme_file = os.getenv("HOME") .. "/.config/sketchybar/current_theme"

-- read theme name from file
local f = io.open(theme_file, "r")
local theme_name = f and f:read("*l") or "white"
if f then f:close() end

local ok, theme = pcall(require, "themes." .. theme_name)

-- safety fallback if theme missing
if not ok then
  theme = require("themes.white")
end

return theme