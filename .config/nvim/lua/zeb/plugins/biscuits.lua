return {
	"code-biscuits/nvim-biscuits",
	config = function()
		require("nvim-biscuits").setup({
			-- Optional: Enable biscuits on startup
			show_on_start = true,

			-- Optional: Toggle visibility with a keybinding
			keys = {
				{
					"<leader>bb",
					function()
						require("nvim-biscuits").BufferAttach()
					end,
					mode = "n",
					desc = "Enable Biscuits",
				},
			},

			-- Optional: Customize the appearance
			highlight = "Comment",
			cursor_line_only = true,
		})
	end,
}
