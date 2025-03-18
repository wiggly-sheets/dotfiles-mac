return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},

	config = function()
		-- Import mason and other dependencies
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local mason_tool_installer = require("mason-tool-installer")

		-- Enable mason and configure icons
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		-- Mason LSP Config setup with the servers to ensure installation
		mason_lspconfig.setup({
			ensure_installed = {
				--			"tsserver", -- TypeScript LSP
				--			"html", -- HTML LSP
				--		"cssls", -- CSS LSP
				--		"tailwindcss", -- Tailwind CSS LSP
				--		"svelte", -- Svelte LSP
				--		"lua_ls", -- Lua LSP
				--			"graphql", -- GraphQL LSP
				--		"emmet_ls", -- Emmet LSP
				--		"prismals", -- Prisma LSP
				--		"pyright", -- Python LSP
				--		"rust-analyzer", -- Rust LSP
				--				"markdown-oxide", -- Markdown LSP
			},
		})

		-- Mason Tool Installer setup with tools to ensure installation
		mason_tool_installer.setup({
			ensure_installed = {
				"prettier", -- Prettier
				"stylua", -- Stylua
				"isort", -- Isort
				"black", -- Black
				"pylint", -- Pylint
				"eslint_d", -- ESLint D
			},
		})

		-- Optional: If you need a custom handler for setting up LSP servers
		--	mason_lspconfig.setup_handlers({
		--		function(server_name)
		--				local opts = {}
		--				require("lspconfig")[server_name].setup(opts)
		--			end,
		--		})
	end,
}
