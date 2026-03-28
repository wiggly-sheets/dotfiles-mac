return {
	"kevinhwang91/nvim-ufo",
	dependencies = {
		"kevinhwang91/promise-async",
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		local ufo = require("ufo")

		-- Prevent folds from collapsing automatically
		vim.o.foldcolumn = "1" -- show fold column
		vim.o.foldlevel = 99 -- all folds open
		vim.o.foldlevelstart = 99 -- prevents folds from closing on buffer open
		vim.o.foldenable = true -- folding active but unfolded by default

		-- Set up folding provider: Treesitter first, then indent fallback
		ufo.setup({
			provider_selector = function(bufnr, filetype, buftype)
				return { "treesitter", "indent" }
			end,
			open_fold_hl_timeout = 150, -- highlight timeout in ms
			-- close_fold_kinds = { "imports", "comment" }, -- optional auto-close
			preview = {
				win_config = {
					border = "rounded",
					winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
					maxheight = 15,
					maxwidth = 80,
				},
			},
		})

		-- Optional keymaps for folding
		local keymap = vim.keymap
		keymap.set("n", "zR", ufo.openAllFolds)
		keymap.set("n", "zM", ufo.closeAllFolds)
		keymap.set("n", "zr", ufo.openFoldsExceptKinds)
		keymap.set("n", "zm", ufo.closeFoldsWith)
	end,
}
