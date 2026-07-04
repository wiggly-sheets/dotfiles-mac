local colors = require("colors")
local icons = require("helpers.icons")

local dnd = sbar.add("item", "dnd", {
	position = "right",
	update_freq = 5,
	padding_left = 0,
	padding_right = 0,
	label = {
		color = colors.white,
	},
})

local dnd_active = false

local function set_icon(active)
	dnd:set({
		label = {
			string = active and icons.dnd.on or icons.dnd.off,
			font = { size = 13 },
			color = active and colors.dnd or colors.grey,
		},
	})
end

local function update_dnd()
	sbar.exec(
		[[defaults read com.apple.controlcenter 'NSStatusItem VisibleCC FocusModes' 2>/dev/null]],
		function(result)
			dnd_active = result:match("1") ~= nil
			set_icon(dnd_active)
		end
	)
end

local function toggle_dnd()
	dnd_active = not dnd_active
	set_icon(dnd_active)
	sbar.exec('osascript -e \'tell application "Shortcuts" to run shortcut "Toggle DND"\'')
end

update_dnd()

dnd:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		toggle_dnd()
	end
end)

dnd:subscribe("routine", update_dnd)

-- ======== Hover effects ========
local function add_hover(item)
	item:subscribe("mouse.entered", function()
		item:set({
			background = {
				drawing = true,
				color = colors.hover,
				corner_radius = 20,
				height = 20,
				x_offset = 2,
			},
		})
	end)

	item:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
		item:set({ background = { drawing = false } })
	end)
end

add_hover(dnd)