return {
	{
		"akinsho/bufferline.nvim",
		dependencies = "nvim-tree/nvim-web-devicons",
		config = function()
			local bufferline = require("bufferline")

			bufferline.setup({
				options = {
					numbers = function(opts)
						return string.format("%s", opts.id) -- show buffer ID
					end,
					close_command = "bdelete! %d",
					right_mouse_command = "bdelete! %d",
					left_mouse_command = "buffer %d",
					middle_mouse_command = nil,
					indicator_icon = "▎",
					buffer_close_icon = "",
					modified_icon = "●",
					close_icon = "",
					left_trunc_marker = "",
					right_trunc_marker = "",
					max_name_length = 30,
					tab_size = 20,
					diagnostics = "nvim_lsp",
					diagnostics_indicator = function(count, level, _, _)
						local icon = level:match("error") and " " or " "
						return " " .. icon .. count
					end,
					offsets = {
						{ filetype = "NvimTree", text = "Explorer", text_align = "left", highlight = "Directory" },
						{
							filetype = "neo-tree",
							text = "File Explorer",
							text_align = "center",
							highlight = "Directory",
						},
					},
					show_buffer_icons = true,
					show_buffer_close_icons = true,
					show_close_icon = true,
					show_tab_indicators = true,
					enforce_regular_tabs = false,
					always_show_bufferline = true,
					sort_by = "id",
					separator_style = "slant",
					hover = {
						enabled = true,
						delay = 200,
						reveal = { "close" },
					},
					custom_areas = {
						right = function()
							local buffers = vim.fn.getbufinfo({ buflisted = 1 })
							local mods = {}
							for _, buf in ipairs(buffers) do
								if vim.api.nvim_buf_get_option(buf.bufnr, "modified") then
									table.insert(mods, "●")
								end
							end
							return mods
						end,
					},
				},
				highlights = {
					fill = { bg = "#1e1e2e" },
					background = { fg = "#c0caf5", bg = "#1e1e2e" },
					buffer_selected = { fg = "#ffffff", bold = true },
					separator = { fg = "#2e2e3e" },
					separator_selected = { fg = "#5c5c5c" },
					indicator_selected = { fg = "#ff9e64" },
					modified = { fg = "#ff9e64" },
				},
			})

			-- Keymaps for fast navigation and actions
			vim.keymap.set("n", "<S-l>", ":BufferLineCycleNext<CR>", { silent = true })
			vim.keymap.set("n", "<S-h>", ":BufferLineCyclePrev<CR>", { silent = true })
			vim.keymap.set("n", "<leader>bp", ":BufferLinePick<CR>", { silent = true })
			vim.keymap.set("n", "<leader>bc", ":BufferLinePickClose<CR>", { silent = true })
			vim.keymap.set("n", "<leader>bm", ":BufferLineSortByModified<CR>", { silent = true })
			vim.keymap.set("n", "<leader>bd", ":BufferLineSortByDirectory<CR>", { silent = true })
		end,
	},
}
