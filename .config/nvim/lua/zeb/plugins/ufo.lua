-- lua/zeb/plugins/folds/ufo.lua
return {
	"kevinhwang91/nvim-ufo",
	dependencies = {
		"kevinhwang91/promise-async",
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		local ufo = require("ufo")

		-- Set up folding provider: Treesitter first, then indent fallback
		ufo.setup({
			provider_selector = function(bufnr, filetype, buftype)
				return { "treesitter", "indent" }
			end,
			open_fold_hl_timeout = 150, -- highlight timeout in ms
			--		close_fold_kinds = { "imports", "comment" }, -- optional, auto-close these fold types
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
		keymap.set("n", "zR", require("ufo").openAllFolds)
		keymap.set("n", "zM", require("ufo").closeAllFolds)
		keymap.set("n", "zr", require("ufo").openFoldsExceptKinds)
		keymap.set("n", "zm", require("ufo").closeFoldsWith) -- close folds of a certain kind
	end,
}
