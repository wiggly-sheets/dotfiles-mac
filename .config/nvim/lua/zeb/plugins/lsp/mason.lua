return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},

	config = function()
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local mason_tool_installer = require("mason-tool-installer")

		-- Mason UI setup
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		-- Ensure LSP servers are installed
		mason_lspconfig.setup({
			ensure_installed = {
				"ts_ls", -- TypeScript
				"html", -- HTML
				"cssls", -- CSS
				"tailwindcss", -- Tailwind
				"svelte", -- Svelte
				"lua_ls", -- Lua
				"graphql", -- GraphQL
				"emmet_ls", -- Emmet
				"prismals", -- Prisma
				"pyright", -- Python
				"rust_analyzer", -- Rust
				"marksman", -- Markdown
			},
			automatic_installation = true, -- auto install missing servers when opening file
		})

		-- Ensure formatters / linters are installed
		mason_tool_installer.setup({
			ensure_installed = {
				"prettier", -- Prettier for JS/TS/HTML/CSS
				"stylua", -- Lua formatter
				"isort", -- Python import sorter
				"black", -- Python formatter
				"pylint", -- Python linter
				"eslint_d", -- JS/TS linter
			},
			auto_update = true, -- auto-update tools
			run_on_start = true, -- run installer on startup
		})
	end,
}
