local theme_path = os.getenv("HOME") .. "/.config/sketchybar/current_theme"

local f = io.open(theme_path, "r")
local theme_name = f and f:read("*l") or "white"
if f then f:close() end

-- clear the module from Lua cache so reload works
package.loaded["themes." .. theme_name] = nil

local ok, theme = pcall(require, "themes." .. theme_name)

if not ok then
    theme = require("themes.white")
end

return theme