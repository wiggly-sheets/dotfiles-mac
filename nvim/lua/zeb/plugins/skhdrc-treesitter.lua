return {
	"nvim-treesitter/nvim-treesitter",
	dependencies = { "aimuzov/tree-sitter-skhdrc" },
	opts = function(_, opts)
		opts.ensure_installed = opts.ensure_installed or {}
		vim.list_extend(opts.ensure_installed, { "skhdrc" })
	end,
}
