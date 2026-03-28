return {
	-- Colorizer: highlights color codes in buffers
	"norcalli/nvim-colorizer.lua",
	config = function()
		require("colorizer").setup({
			"*", -- highlight all files
			css = { rgb_fn = true }, -- enable css functions like rgb()
			html = { names = true }, -- enable named colors
		})
	end,
}
