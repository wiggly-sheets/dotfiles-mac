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
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.guicursor = "n-ci:hor30-iCursor,v-c-r-i-sm-t:ver25,a:blinkwait300-blinkon200-blinkoff150,"

-- Make floating windows transparent
vim.cmd([[
  hi NormalFloat guibg=NONE ctermbg=NONE
  hi FloatBorder guibg=NONE ctermbg=NONE
  hi Pmenu guibg=NONE ctermbg=NONE
  hi PmenuSel guibg=#3b4261 guifg=#c0caf5
  hi TelescopeNormal guibg=NONE
  hi TelescopeBorder guibg=NONE guifg=#7aa2f7
  hi TelescopePromptNormal guibg=NONE
  hi TelescopePromptBorder guibg=NONE guifg=#7aa2f7
  hi TelescopePromptTitle guibg=NONE guifg=#7aa2f7
  hi TelescopePreviewTitle guibg=NONE guifg=#7aa2f7
  hi TelescopeResultsTitle guibg=NONE
  hi TelescopeSelection guibg=#3b4261 guifg=#c0caf5
  hi LazyNormal guibg=NONE
  hi LazyFloat guibg=NONE
]])
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		math.randomseed(os.time())
		local fg_color = tostring(math.random(0, 12))
		local hi_setter = "hi AlphaHeader ctermfg="
		vim.cmd(hi_setter .. fg_color)
	end,
})
