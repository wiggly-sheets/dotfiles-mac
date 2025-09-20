-- ~/.config/nvim/lua/plugins/scrollbar.lua
return {
	"petertriho/nvim-scrollbar",
	event = "BufReadPost",
	config = function()
		require("scrollbar").setup({
			show = true,
			handle = {
				text = " ",
				color = "#A3BE8C",
				hide_if_all_visible = true,
			},
			marks = {
				Search = { color = "#EBCB8B" },
				Error = { color = "#BF616A" },
				Warn = { color = "#D08770" },
				Info = { color = "#88C0D0" },
				Hint = { color = "#B48EAD" },
			},
		})
	end,
}
