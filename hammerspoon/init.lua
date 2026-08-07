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
-- For example, you don't want this plugin overriding your control of Terminal  vim
vim:disableForApp("kitty")
	:disableForApp("iTerm")
    :disableForApp("iTerm2")
	:disableForApp("Ghostyy")
	:disableForApp("Terminal")
    :disableForApp("Wezterm")
    :disableForApp("Neovide")
	:disableForApp("MarkEdit")

-- If you want the screen to dim (a la Flux) when you enter normal mode
-- flip this to true.
vim:shouldDimScreenInNormalMode(false)

-- If you want to show an on-screen alert when you enter normal mode, set
-- this to true
vim:shouldShowAlertInNormalMode(true)

-- You can configure your on-screen alert font
vim:setAlertFont("Liga SFMono Nerd Font")

-- Enter normal mode by typing a key sequence
vim:enterWithSequence("vm")

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
