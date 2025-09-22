return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		local mason = require("mason")
		mason.setup({
			ui = {
				icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" },
			},
		})

		-- safe require, no notify
		local ok, mason_lspconfig = pcall(require, "mason-lspconfig")
		if ok then
			mason_lspconfig.setup({
				ensure_installed = {
					"ts_ls",
					"html",
					"cssls",
					"tailwindcss",
					"svelte",
					"lua_ls",
					"graphql",
					"emmet_ls",
					"prismals",
					"pyright",
					"rust_analyzer",
					"marksman",
				},
				automatic_installation = true,
			})
		end

		local ok2, mason_tool_installer = pcall(require, "mason-tool-installer")
		if ok2 then
			mason_tool_installer.setup({
				ensure_installed = { "prettier", "stylua", "isort", "black", "pylint", "eslint_d" },
				auto_update = true,
				run_on_start = true,
			})
		end
	end,
}
