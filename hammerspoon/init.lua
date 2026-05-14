--------------------------------
-- START GENERAL HAMMERSPOON CONFIG
--------------------------------
hs.loadSpoon("SpoonInstall")
hs.allowAppleScript(true)

--------------------------------
-- END GENERAL HAMMERSPOON CONFIG
--------------------------------

--------------------------------
-- START VIM CONFIG
--------------------------------
local VimMode = hs.loadSpoon("VimMode")
local vim = VimMode:new()

-- Configure apps you do *not* want Vim mode enabled in
-- For example, you don't want this plugin overriding your control of Terminal
-- vim
vim:disableForApp("zoom.us")
	:disableForApp("iTerm")
	:disableForApp("iTerm2")
	:disableForApp("Terminal")
	:disableForApp("Wezterm")

-- If you want the screen to dim (a la Flux) when you enter normal mode
-- flip this to true.
vim:shouldDimScreenInNormalMode(false)

-- If you want to show an on-screen alert when you enter normal mode, set
-- this to true
vim:shouldShowAlertInNormalMode(true)

-- You can configure your on-screen alert font
vim:setAlertFont("Liga SFMono Nerd Font")

-- Enter normal mode by typing a key sequence
vim:enterWithSequence("jk")

-- if you want to bind a single key to entering vim, remove the
-- :enterWithSequence('jk') line above and uncomment the bindHotKeys line
-- below:
--
-- To customize the hot key you want, see the mods and key parameters at:
-- https://www.hammerspoon.org/docs/hs.hotkey.html#bind
--
-- vim:bindHotKeys({
--	enter = { {}, "escape" },
-- })
--------------------------------
-- END VIM CONFIG
--------------------------------

--------------------------------
-- START YABAI GRID SPACES CONFIG
--------------------------------

hs.loadSpoon("YabaiGridSpaces")
spoon.YabaiGridSpaces
	:applyConfig({
		yabaiPath = "/opt/homebrew/bin/yabai",
		numberOfColumns = 3,
		gridDisplayTimeout = 2,
		gridScale = 0.2,
	})
	:bindHotKeys({
		-- https://www.hammerspoon.org/docs/hs.hotkey.html
		navigateNorth = { { "ctrl", "shift" }, "k" },
		navigateEast = { { "ctrl", "shift" }, "l" },
		navigateSouth = { { "ctrl", "shift" }, "j" },
		navigateWest = { { "ctrl", "shift" }, "h" },

		moveWindowNorth = { { "cmd", "ctrl", "shift" }, "k" },
		moveWindowSouth = { { "cmd", "ctrl", "shift" }, "j" },
		moveWindowEast = { { "cmd", "ctrl", "shift" }, "l" },
		moveWindowWest = { { "cmd", "ctrl", "shift" }, "h" },
	})
	:start()

--------------------------------
-- END YABAI GRID SPACES CONFIG
--------------------------------
