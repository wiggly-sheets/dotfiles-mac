return {
	"folke/noice.nvim",
	dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
	config = function()
		vim.notify = require("notify")
		require("noice").setup({
			-- your settings here
		})
	end,
}
