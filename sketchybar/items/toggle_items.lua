local colors = require("colors")
local icons = require("icons")
local settings = require("default")

local hidden = true

local items_to_toggle = {
	"weather",
	"battery",
	"display",
	"lowpowermode",
	"network",
	"storage",
	"temperature",
	"cpu",
	"ram",
	"cpu_temp",
	"gpu_temp",
	"wifi.status",
	"wifi1",
	"wifi2",
	"net_graph_up",
	"net_graph_down",
	"volume",
	"mic",
	"storage_label",
	"storage_icon",
}

local toggle_items = sbar.add("item", "toggle_items", {
	position = "right",
	icon = {
		string = icons.menus.contract,
		color = colors.white,
		font = { family = settings.default, size = 12 },
	},
	label = {
		drawing = false,
	},
	padding_left = 2,
	padding_right = 2,
})

local function set_items(visible)
	for _, item in ipairs(items_to_toggle) do
		if visible then
			sbar.set(item, {
				drawing = true,
				icon = { drawing = true },
				label = { drawing = true },
			})
		else
			sbar.set(item, {
				drawing = false,
				icon = { drawing = false },
				label = { drawing = false },
			})
		end
	end
end

-- Initialize hidden state on load (force after all items are created)
set_items(not hidden)
sbar.set("toggle_items", {
	icon = {
		string = hidden and icons.menus.expand or icons.menus.contract,
	},
})

-- Force reapply after SketchyBar finishes loading everything
sbar.exec("sleep 0.1 && sketchybar --trigger toggle_items_init")

toggle_items:subscribe("mouse.clicked", function()
	hidden = not hidden
	set_items(not hidden)
	sbar.set("toggle_items", {
		icon = {
			string = hidden and icons.menus.expand or icons.menus.contract,
		},
	})
end)

toggle_items:subscribe("toggle_items_init", function()
	set_items(not hidden)
end)

-- ======== Hover effects ========
local function add_hover(item)
	item:subscribe("mouse.entered", function()
		item:set({
			background = {
				drawing = true,
				color = colors.hover,
				corner_radius = 20,
				height = 20,
				x_offset = 1,
			},
		})
	end)

	item:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
		item:set({ background = { drawing = false } })
	end)
end

add_hover(toggle_items)
