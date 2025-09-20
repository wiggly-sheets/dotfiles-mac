-- ~/.config/nvim/lua/plugins/vim-visual-multi.lua
return {
	"mg979/vim-visual-multi",
	branch = "master",
	event = "VeryLazy", -- lazy-load
	config = function()
		vim.g.VM_leader = "\\"
	end,
}
