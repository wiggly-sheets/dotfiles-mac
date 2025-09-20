return {
	"numToStr/FTerm.nvim",
	config = function()
		require("FTerm").setup({
			border = "single",
			dimensions = { height = 0.8, width = 0.8 },
			blend = 0,
		})
		vim.api.nvim_set_keymap(
			"n",
			"<leader>t",
			"<cmd>lua require('FTerm').toggle()<CR>",
			{ noremap = true, silent = true }
		)
	end,
}
