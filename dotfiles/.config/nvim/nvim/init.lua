require("zeb.core.options")
require("zeb.core")
require("zeb.core.keymaps")
require("zeb.lazy")
require("asciiart").setup({
	render = {
		min_padding = 5,
		show_label = true,
		use_dither = true,
		foreground_color = true,
		background_color = true,
	},
	events = {
		update_on_nvim_resize = true,
	},
})
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		math.randomseed(os.time())
		local fg_color = tostring(math.random(0, 12))
		local hi_setter = "hi AlphaHeader ctermfg="
		vim.cmd(hi_setter .. fg_color)
	end,
})
