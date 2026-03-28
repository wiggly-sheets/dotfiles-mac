-- ~/.config/nvim/lua/plugins/fidget.lua
return {
	"j-hui/fidget.nvim",
	tag = "legacy", -- optional, stable version
	event = "LspAttach",
	config = function()
		require("fidget").setup({
			text = {
				spinner = "dots", -- spinner style: dots, line, bounce, etc
				done = "✔", -- completed symbol
				commenced = "⏳", -- starting symbol
				completed = "✔", -- finished symbol
			},
			align = {
				bottom = true, -- show at bottom
				right = true, -- align right
			},
			fmt = {
				leftpad = true, -- add space before fidget text
				stack_upwards = true, -- stack multiple tasks upwards
				max_width = 0, -- 0 = no limit
			},
			timer = {
				spinner_rate = 125, -- speed of spinner animation
				fidget_decay = 2000, -- fade out completed fidgets
				task_decay = 1000, -- fade out individual tasks
			},
			window = {
				relative = "editor", -- floating window relative to editor
				blend = 0, -- transparency (0-100)
				zindex = 50, -- window stacking
			},
			sources = {
				["*"] = { ignore = false }, -- show all sources by default
			},
			debug = {
				logging = false, -- disable debug logs
				strict = false,
			},
			-- optional Tokyonight colors
			colors = {
				fidget = { "fg=#a9b1d6" }, -- soft blue/purple for spinner text
				task = { "fg=#9ece6a" }, -- green for active tasks
				completed = { "fg=#7aa2f7" }, -- light blue for done
			},
		})
	end,
}
