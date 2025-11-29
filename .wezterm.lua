--pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration
local config = wezterm.config_builder()

config.window_close_confirmation = "NeverPrompt"

config.front_end = "WebGpu"

config.font = wezterm.f
ont_with_fallback({
	"Liga SFMono Nerd Font",
})
config.font_size = 12

TERM = "wezterm"

require("wezterm").on("format-window-title", function()
	return "WezTerm"
end)

config.color_scheme = "Tokyo Night"

config.enable_kitty_graphics = true
config.enable_tab_bar = false
config.window_decorations = "RESIZE"

config.warn_about_missing_glyphs = false

config.cursor_blink_rate = 500
config.animation_fps = 50

config.window_background_opacity = 0.2
config.macos_window_background_blur = 10

config.window_padding = {
	left = 8,
	right = 0,
	top = 0,
	bottom = 0,
}

wezterm.on("user-var-changed", function(window, pane, name, value)
	local overrides = window:get_config_overrides() or {}
	if name == "ZEN_MODE" then
		local incremental = value:find("+")
		local number_value = tonumber(value)
		if incremental ~= nil then
			while number_value > 0 do
				window:perform_action(wezterm.action.IncreaseFontSize, pane)
				number_value = number_value - 1
			end
			overrides.enable_tab_bar = false
		elseif number_value < 0 then
			window:perform_action(wezterm.action.ResetFontSize, pane)
			overrides.font_size = nil
			overrides.enable_tab_bar = true
		else
			overrides.font_size = number_value
			overrides.enable_tab_bar = false
		end
	end
	window:set_config_overrides(overrides)
end)

return config
