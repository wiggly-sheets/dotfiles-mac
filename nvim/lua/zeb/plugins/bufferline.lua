return {
	{
		"akinsho/bufferline.nvim",
		dependencies = "nvim-tree/nvim-web-devicons",
		config = function()
			require("bufferline").setup({
				options = {
					numbers = function(opts)
						return string.format("%s", opts.id)
					end,

					close_command = "bdelete! %d",
					right_mouse_command = "bdelete! %d",
					left_mouse_command = "buffer %d",

					indicator = { style = "icon" },
					separator_style = "thin",
					buffer_close_icon = "󰅖",
					modified_icon = "●",
					close_icon = "",
					left_trunc_marker = "",
					right_trunc_marker = "",

					max_name_length = 30,
					tab_size = 20,
					sort_by = "id",
					always_show_bufferline = true,

					diagnostics = "nvim_lsp",
					diagnostics_indicator = function(count, level)
						local icon = level:match("error") and "" or ""
						return " " .. icon .. " " .. count
					end,

					offsets = {
						{
							filetype = "NvimTree",
							text = "File Explorer",
							highlight = "Directory",
							text_align = "left",
						},
						{
							filetype = "neo-tree",
							text = "File Explorer",
							highlight = "Directory",
							text_align = "center",
						},
					},

					hover = {
						enabled = true,
						delay = 150,
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

				-- transparent + clean highlight overrides
				highlights = {
					fill = { bg = "NONE" },
					background = { bg = "NONE" },

					buffer_selected = {
						bg = "NONE",
						bold = true,
						italic = false,
						fg = "#ffffff",
					},

					separator = { fg = "#3a3a3a", bg = "NONE" },
					separator_selected = { fg = "#6b6b6b", bg = "NONE" },

					indicator_selected = {
						fg = "#ff9e64",
						bg = "NONE",
					},

					modified = { fg = "#ff9e64", bg = "NONE" },
					modified_selected = { fg = "#ff9e64", bg = "NONE" },

					diagnostic = { bg = "NONE" },
					diagnostic_selected = { bg = "NONE" },
				},
			})

			-- Keymaps
			local map = vim.keymap.set
			map("n", "<S-l>", ":BufferLineCycleNext<CR>", { silent = true })
			map("n", "<S-h>", ":BufferLineCyclePrev<CR>", { silent = true })
			map("n", "<leader>bp", ":BufferLinePick<CR>", { silent = true })
			map("n", "<leader>bc", ":BufferLinePickClose<CR>", { silent = true })
			map("n", "<leader>bm", ":BufferLineSortByModified<CR>", { silent = true })
			map("n", "<leader>bd", ":BufferLineSortByDirectory<CR>", { silent = true })
		end,
	},
}
