local colors = require("colors")
local settings = require("settings")

-- Main item (the Vim mode indicator)
local svim_mode = sbar.add("item", "svim.mode", {
	position = "left",
	icon = { string = "", font = settings.default, color = colors.red },
	label = { font = settings.default, drawing = true },
	popup = { align = "right", drawing = false },
	updates = true,
})

-- Popup item for commandline
local svim_cmdline = sbar.add("item", "svim.cmdline", {
	position = "popup.svim.mode",
	icon = { string = "Command: " },
	label = { string = "" },
})

-- Update logic (called whenever SketchyVim triggers an update)
local function update(env)
	local mode = env.MODE or ""
	local cmdline = env.CMDLINE or ""

	local color = mode ~= "" and colors.green or colors.red
	local label_drawing = mode ~= "" and "on" or "off"
	local popup_drawing = cmdline ~= "" and "on" or "off"

	-- Update main mode item
	svim_mode:set({
		icon = { color = color },
		label = {
			string = mode ~= "" and ("[" .. mode .. "]") or "",
			drawing = label_drawing,
		},
		popup = { drawing = popup_drawing },
	})

	-- Update popup cmdline item
	svim_cmdline:set({ label = { string = cmdline } })
end

-- SketchyVim triggers these events with MODE/CMDLINE set in the environment
svim_mode:subscribe({ "front_app_switched", "window_focus", update })
