-- ~/.config/nvim/lua/plugins/cheatsheet.lua
return {
	"sudormrfbin/cheatsheet.nvim",
	cmd = "Cheatsheet", -- lazy-load on command
	config = function()
		require("cheatsheet").setup({
			bundled_cheatsheets = true,
			bundled_plugin_cheatsheets = true,
		})
	end,
}
