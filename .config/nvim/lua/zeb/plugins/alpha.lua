return {
	"goolord/alpha-nvim",
	event = "VimEnter",
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")
		local plugins_count = require("lazy").stats().count
		-- Set header
		dashboard.section.header.val = {
			[[                                                                   ]],
			[[      ████ ██████           █████      ██                    ]],
			[[     ███████████             █████                            ]],
			[[     █████████ ███████████████████ ███   ███████████  ]],
			[[    █████████  ███    █████████████ █████ ██████████████  ]],
			[[   █████████ ██████████ █████████ █████ █████ ████ █████  ]],
			[[ ███████████ ███    ███ █████████ █████ █████ ████ █████ ]],
			[[██████  █████████████████████ ████ █████ █████ ████ ██████]],
		}

		-- Set menu
		dashboard.section.buttons.val = {
			dashboard.button("e", "  > New File", "<cmd>ene<CR>"),
			dashboard.button("SPC ee", "  > File explorer", "<cmd>NvimTreeToggle<CR>"),
			dashboard.button("SPC ff", "󰱼  > Find File", "<cmd>Telescope find_files hidden=true<CR>"),
			dashboard.button("SPC fs", "  > Find Word", "<cmd>Telescope live_grep<CR>"),
			dashboard.button("SPC wr", "󰁯  > Restore Session For Current Directory", "<cmd>SessionRestore<CR>"),
			dashboard.button("q", "  > Quit", "<cmd>qa<CR>"),
		}

		local function nvim_info()
			local plugins_count = require("lazy").stats().count
			local nvim_version = vim.version()
			local nvim_ver_str = string.format("%d.%d.%d", nvim_version.major, nvim_version.minor, nvim_version.patch)
			local zsh_ver = vim.fn.system(vim.env.SHELL .. " --version"):gsub("\n", "")
			return {
				" Neovim " .. nvim_ver_str,
				" Plugins: " .. plugins_count,
				" " .. _VERSION,
				" Shell: " .. zsh_ver,
			}
		end

		dashboard.section.footer.val = nvim_info()
		-- Send config to alpha
		alpha.setup(dashboard.opts)

		-- Disable folding on alpha buffer
		vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])

		-- Hide statusline and tabline when alpha is open
		vim.api.nvim_create_autocmd("User", {
			pattern = "AlphaReady",
			callback = function()
				vim.go.laststatus = 0
				vim.opt.showtabline = 0
			end,
		})

		-- Restore statusline and tabline when leaving alpha
		vim.api.nvim_create_autocmd("BufUnload", {
			buffer = 0,
			callback = function()
				vim.go.laststatus = 2
				vim.opt.showtabline = 2
			end,
		})
	end,
}
