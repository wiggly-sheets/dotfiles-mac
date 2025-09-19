--pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration
local config = wezterm.config_builder()

config.window_close_confirmation = "NeverPrompt"

config.front_end = "OpenGL"

config.font = wezterm.font_with_fallback({
	"Inconsolata Nerd Font Mono",
	"IosevkaTermSlab Nerd Font Mono",
	"JetBrains Mono",
})
config.font_size = 15

TERM = "wezterm"

config.color_scheme = "Dark Pastel"

config.enable_kitty_graphics = true
config.enable_tab_bar = false
config.window_decorations = "RESIZE"

config.warn_about_missing_glyphs = true

config.default_cursor_style = "BlinkingUnderline"
config.cursor_blink_rate = 500
config.animation_fps = 50

config.window_background_opacity = 0.5
config.macos_window_background_blur = 20

config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

return config
