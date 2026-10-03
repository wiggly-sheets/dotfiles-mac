local setup_path = os.getenv("HOME") .. "/.config/sketchybar/setups/current_setup"

local f = io.open(setup_path, "r")
local setup_name = f and f:read("*l") or "default"
if f then
	f:close()
end

local ok, setup = pcall(require, "setups." .. setup_name)

if not ok then
	setup = require("setups.default")
end

return setup
