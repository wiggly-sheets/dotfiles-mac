local colors = require("colors")
local settings = require("default")

-- Generic popup menu anchored to an item. Rows are rebuilt on every open.
local M = {}

local prefixes = {}
local anchored = {}

local function clear_all()
	for prefix in pairs(prefixes) do
		sbar.remove("/" .. prefix .. "\\..*/")
		sbar.remove(prefix:match("^(.*)%.item$") .. ".header")
	end
end

-- opts.prefix: "<name>.item" used to name the header and row items
-- opts.rows: list of { label = string, active = bool, script = string }
function M.open(anchor, opts)
	local name = opts.prefix:match("^(.*)%.item$")

	prefixes[opts.prefix] = true
	clear_all()

	sbar.add("item", name .. ".header", {
		position = "popup." .. anchor.name,
		label = {
			string = opts.title,
			font = { family = settings.default, size = 11, style = "Bold" },
		},
		padding_left = 10,
		padding_right = 10,
	})

	for i, row in ipairs(opts.rows) do
		sbar.add("item", opts.prefix .. "." .. i, {
			position = "popup." .. anchor.name,
			label = row.label,
			background = {
				drawing = row.active,
				color = row.active and colors.hover or colors.transparent,
				corner_radius = 20,
			},
			click_script = row.script,
		})
	end

	if not anchored[anchor.name] then
		anchor:subscribe("mouse.exited.global", function()
			anchor:set({ popup = { drawing = false } })
			clear_all()
		end)
		anchored[anchor.name] = true
	end
end

return M
