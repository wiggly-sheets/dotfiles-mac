return {
	"p00f/nvim-ts-rainbow",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	config = function()
		require("nvim-treesitter.configs").setup({
			rainbow = {
				enable = true,
				extended_mode = true, -- highlight non-bracket delimiters
				max_file_lines = nil,
			},
		})
	end,
}
