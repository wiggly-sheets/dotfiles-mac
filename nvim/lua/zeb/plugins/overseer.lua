-- ~/.config/nvim/lua/plugins/overseer.lua
return {
	"stevearc/overseer.nvim",
	cmd = { "OverseerRun", "OverseerToggle", "OverseerTaskAction" },
	config = function()
		require("overseer").setup({
			strategy = "toggleterm",
			auto_close = true,
		})
	end,
}
