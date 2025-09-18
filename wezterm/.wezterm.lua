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
	"Noto Sans Mono",
	"Apple Color Emoji",
	"SF Pro Display",
})
config.font_size = 15

require("wezterm").on("format-window-title", function()
	return "WezTerm"
end)

TERM = "wezterm"
-- TERM = "xterm-kitty"

config.color_scheme = "Dark Pastel"

config.enable_kitty_graphics = true
config.enable_tab_bar = false
config.window_decorations = "RESIZE"

config.harfbuzz_features = { "calt=1", "clig=1", "liga=1", "dlig=1" }
config.warn_about_missing_glyphs = false

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

config.colors = {
	--	background = "#000000",
	cursor_bg = "#47FF9C",
	cursor_border = "#47FF9C",
	cursor_fg = "#011423",
	selection_bg = "#033259",
	selection_fg = "#CBE0F0",
	ansi = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#0FC5ED", "#a277ff", "#24EAF7", "#24EAF7" },
	brights = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#A277FF", "#a277ff", "#24EAF7", "#24EAF7" },
}

return config
