-- ~/.config/nvim/lua/plugins/project.lua
return {
	"ahmedkhalf/project.nvim",
	event = "VimEnter",
	config = function()
		require("project_nvim").setup({
			manual_mode = false,
			detection_methods = { "pattern", "lsp" },
			patterns = { ".git", "package.json", "Makefile", "Cargo.toml" },
			show_hidden = true,
		})
		require("telescope").load_extension("projects")
	end,
}
