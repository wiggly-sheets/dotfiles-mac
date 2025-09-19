return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local lazy_status = require("lazy.status")

		-- transparent-friendly theme
		local my_lualine_theme = {
			normal = {
				a = { bg = "none", fg = "#65D1FF", gui = "bold" },
				b = { bg = "none", fg = "#c3ccdc" },
				c = { bg = "none", fg = "#c3ccdc" },
			},
			insert = {
				a = { bg = "none", fg = "#3EFFDC", gui = "bold" },
				b = { bg = "none", fg = "#c3ccdc" },
				c = { bg = "none", fg = "#c3ccdc" },
			},
			visual = {
				a = { bg = "none", fg = "#FF61EF", gui = "bold" },
				b = { bg = "none", fg = "#c3ccdc" },
				c = { bg = "none", fg = "#c3ccdc" },
			},
			command = {
				a = { bg = "none", fg = "#FFDA7B", gui = "bold" },
				b = { bg = "none", fg = "#c3ccdc" },
				c = { bg = "none", fg = "#c3ccdc" },
			},
			replace = {
				a = { bg = "none", fg = "#FF4A4A", gui = "bold" },
				b = { bg = "none", fg = "#c3ccdc" },
				c = { bg = "none", fg = "#c3ccdc" },
			},
			inactive = {
				a = { bg = "none", fg = "#666666", gui = "bold" },
				b = { bg = "none", fg = "#666666" },
				c = { bg = "none", fg = "#666666" },
			},
		}

		require("lualine").setup({
			options = {
				theme = my_lualine_theme,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_x = {
					{
						lazy_status.updates,
						cond = lazy_status.has_updates,
						color = { fg = "#ff9e64" },
					},
					{ "encoding" },
					{ "fileformat", symbols = { unix = "" } },
					{ "filetype" },
				},
			},
		})
	end,
}
