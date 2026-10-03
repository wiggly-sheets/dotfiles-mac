-- Loaded by every setup: the apple menu (left = themes, right = setups) and the
-- lock/unlock bar animation.
require("items.left.apple")
require("items.startup_animation")

local setup = require("setups")

for _, module in ipairs(setup.items) do
	require(module)
end

if setup.brackets then
	require("items.brackets").add(setup.brackets)
end
