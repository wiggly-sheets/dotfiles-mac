return {
	"folke/twilight.nvim",
	config = function()
		require("twilight").setup({
			dimming = { alpha = 0.25 },
			treesitter = true,
			expand = { "function", "method", "table" },
		})
		-- optional toggle keybinding
		vim.api.nvim_set_keymap("n", "<leader>z", "<cmd>Twilight<CR>", { noremap = true, silent = true })
	end,
}
