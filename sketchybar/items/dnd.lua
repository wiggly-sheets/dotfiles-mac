local colors = require("colors")
local icons = require("helpers.icons")

local dnd = sbar.add("item", "dnd", {
	label = {
		drawing = true,
		string = icons.dnd_off,
		font = { size = 13 },
	},
	position = "right",
	padding_right = 0,
	padding_left = 0,
	update_freq = 5,
})

local function set_dnd_icon()
	dnd:set({
		label = {
			string = dnd_active and icons.dnd.on or icons.dnd.off,
			color = dnd_active and colors.dnd or colors.grey,
		},
	})
end

local function update_dnd()
	sbar.exec(
		[[defaults read com.apple.controlcenter 'NSStatusItem VisibleCC FocusModes' 2>/dev/null]],
		function(result)
			dnd_active = result:match("1") ~= nil
			set_dnd_icon()
		end
	)
end

dnd:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		dnd_active = not dnd_active
		set_dnd_icon()
		sbar.exec('osascript -e \'tell application "Shortcuts" to run shortcut "Toggle DND"\'')
	end
end)

update_dnd()

dnd:subscribe("routine", "system_woke", update_dnd())

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
