-- ~/.config/nvim/lua/plugins/nvim-lightbulb.lua
return {
	"kosayoda/nvim-lightbulb",
	event = "LspAttach",
	config = function()
		require("nvim-lightbulb").setup({
			autocmd = { enabled = true },
			sign = { enabled = true, priority = 20 },
			float = { enabled = true, win_opts = { winblend = 0 } },
		})
	end,
}
