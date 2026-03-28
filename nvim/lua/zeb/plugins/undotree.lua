-- ~/.config/nvim/lua/plugins/undotree.lua
return {
	"mbbill/undotree",
	cmd = "UndotreeToggle", -- lazy-load when toggled
	config = function()
		vim.g.undotree_WindowLayout = 2
		vim.g.undotree_SetFocusWhenToggle = 1
	end,
}
