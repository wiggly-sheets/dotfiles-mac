return {
	"folke/zen-mode.nvim",
	dependencies = { "folke/twilight.nvim" },

	config = function()
		local zen_mode = require("zen-mode")
		local twilight = require("twilight")

		-- Configure Twilight (dim inactive code)
		twilight.setup({
			dimming = {
				alpha = 0.25, -- amount of dimming outside of focus
				color = { "Normal", "#000000" },
			},
			context = 10, -- number of lines around the cursor to keep bright
			treesitter = true,
			expand = { "function", "method", "table", "if_statement" },
		})

		-- Configure Zen Mode
		zen_mode.setup({
			window = {
				width = 0.8, -- 80% of the screen
				options = {
					number = false,
					relativenumber = false,
					signcolumn = "no",
				},
			},
			plugins = {
				twilight = { enabled = true }, -- automatically enable twilight
				gitsigns = { enabled = false },
				kitty = { enabled = false, font = "+2" },
			},
			on_open = function()
				-- Optionally dim other UI elements
				vim.opt.laststatus = 0 -- hide statusline
				vim.opt.showtabline = 0
			end,
			on_close = function()
				vim.opt.laststatus = 2 -- restore statusline
				vim.opt.showtabline = 2
			end,
		})

		-- Optional keymap to toggle Zen Mode
		vim.keymap.set("n", "<leader>z", "<cmd>ZenMode<CR>", { noremap = true, silent = true })
	end,
}
