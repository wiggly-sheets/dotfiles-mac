return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local lazy_status = require("lazy.status")

		-- Tokyonight colors + transparency
		local tn = {
			bg = "NONE",
			fg = "#c0caf5",
			blue = "#7aa2f7",
			green = "#9ece6a",
			magenta = "#bb9af7",
			red = "#f7768e",
			yellow = "#e0af68",
			cyan = "#7dcfff",
			inactive = "#565f89",
		}

		-- Transparent Tokyonight-inspired theme
		local transparent = {
			normal = {
				a = { fg = tn.bg, bg = tn.blue, gui = "bold" },
				b = { fg = tn.blue, bg = tn.bg },
				c = { fg = tn.fg, bg = tn.bg },
				x = { fg = tn.fg, bg = tn.bg },
				y = { fg = tn.fg, bg = tn.bg },
				z = { fg = tn.bg, bg = tn.blue, gui = "bold" },
			},
			insert = {
				a = { fg = tn.bg, bg = tn.green, gui = "bold" },
				b = { fg = tn.green, bg = tn.bg },
				c = { fg = tn.fg, bg = tn.bg },
			},
			visual = {
				a = { fg = tn.bg, bg = tn.magenta, gui = "bold" },
				b = { fg = tn.magenta, bg = tn.bg },
				c = { fg = tn.fg, bg = tn.bg },
			},
			replace = {
				a = { fg = tn.bg, bg = tn.red, gui = "bold" },
				b = { fg = tn.red, bg = tn.bg },
				c = { fg = tn.fg, bg = tn.bg },
			},
			command = {
				a = { fg = tn.bg, bg = tn.yellow, gui = "bold" },
				b = { fg = tn.yellow, bg = tn.bg },
				c = { fg = tn.fg, bg = tn.bg },
			},
			inactive = {
				a = { fg = tn.inactive, bg = tn.bg },
				b = { fg = tn.inactive, bg = tn.bg },
				c = { fg = tn.inactive, bg = tn.bg },
			},
		}

		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = transparent,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				globalstatus = false,
				refresh = {
					statusline = 1000,
					tabline = 1000,
					winbar = 1000,
					refresh_time = 16,
				},
			},

			sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = {},
			},

			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = {},
			},

			winbar = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = { "filename", "selectioncount" }, 
				lualine_x = {
	{
  function()
    local buf = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_active_clients({ bufnr = buf })
    if #clients == 0 then return "" end

    local names = {}
    for _, client in ipairs(clients) do
      table.insert(names, client.name)
    end

    return table.concat(names, ", ")
  end,
  icon = "",
  cond = function()
    return #vim.lsp.get_active_clients({ bufnr = vim.api.nvim_get_current_buf() }) > 0
  end,
},
 				 "encoding",
 				 "fileformat",
  				 "filetype",
 				 "filesize",
  				 "searchcount",
},				lualine_y = { "progress" },
				lualine_z = { "location" },
			},

			inactive_winbar = {
				lualine_c = { "filename" },
				lualine_x = { "location" },
			},
		})

		----------------------------------------------------------------
		-- 🔹 Winbar transparency (YOUR REQUESTED BLOCK INTEGRATED HERE)
		----------------------------------------------------------------
		vim.api.nvim_set_hl(0, "WinBar", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "WinBarNC", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "LualineWinbar", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "LualineWinbarNC", { bg = "NONE" })

		-- ensure separators stay disabled for the floating-style winbar
		require("lualine").setup({
			options = {
				component_separators = "",
				section_separators = "",
			},
		})
		----------------------------------------------------------------

		-- 🔹 Force lualine highlight transparency once everything is loaded
		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			callback = function()
				for _, group in ipairs({
					"LualineA_normal",
					"LualineB_normal",
					"LualineC_normal",
					"LualineX_normal",
					"LualineY_normal",
					"LualineZ_normal",
					"LualineA_insert",
					"LualineB_insert",
					"LualineC_insert",
					"LualineX_insert",
					"LualineY_insert",
					"LualineZ_insert",
					"LualineA_visual",
					"LualineB_visual",
					"LualineC_visual",
					"LualineX_visual",
					"LualineY_visual",
					"LualineZ_visual",
					"LualineA_replace",
					"LualineB_replace",
					"LualineC_replace",
					"LualineX_replace",
					"LualineY_replace",
					"LualineZ_replace",
					"LualineA_command",
					"LualineB_command",
					"LualineC_command",
					"LualineX_command",
					"LualineY_command",
					"LualineZ_command",
					"LualineA_inactive",
					"LualineB_inactive",
					"LualineC_inactive",
					"LualineX_inactive",
					"LualineY_inactive",
					"LualineZ_inactive",
				}) do
					vim.cmd("hi " .. group .. " guibg=NONE ctermbg=NONE")
				end
			end,
		})

		-- 🔹 Hide winbar in Alpha
		vim.api.nvim_create_autocmd("FileType", {
			pattern = {
				"alpha", -- your splash screen
				"neo-tree", -- file tree
				"dashboard", -- if you use dashboard-nvim
				"help", -- help pages
				"qf", -- quickfix
				"lazy", -- Lazy UI
				"mason", -- Mason UI
				"notify", -- notifications
			},
			callback = function()
				vim.opt_local.winbar = nil
			end,
		})

		-- 🔹 Fake inactive winbar behavior
		vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
			callback = function()
				vim.wo.winbar = "%{%v:lua.require'lualine'.statusline()%}"
			end,
		})

		vim.api.nvim_create_autocmd("WinLeave", {
			callback = function()
				vim.wo.winbar = ""
			end,
		})
	end,
}
