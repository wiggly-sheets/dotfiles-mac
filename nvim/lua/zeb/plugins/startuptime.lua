-- ~/.config/nvim/lua/plugins/startuptime.lua
return {
	"dstein64/vim-startuptime",
	cmd = "StartupTime",
	config = function()
		-- Optional: default arguments
		vim.g.startuptime_tries = 10
	end,
}
