return {
	"MeanderingProgrammer/render-markdown.nvim",
	enabled = true,
	init = function()
		-- Better color palette for markdown
		local color_bg = "#1e1e2e" -- background for headings
		local color_fg = "#cdd6f4" -- general foreground text
		local heading_colors = { -- different heading levels
			"#f38ba8", -- H1
			"#fab387", -- H2
			"#f9e2af", -- H3
			"#a6e3a1", -- H4
			"#89b4fa", -- H5
			"#b4befe", -- H6
		}
		local inline_code_bg = "#313244"
		local inline_code_fg = "#f5c2e7"

		-- Headline background highlights
		for i = 1, 6 do
			vim.cmd(string.format("highlight Headline%dBg guifg=%s guibg=%s", i, color_fg, heading_colors[i]))
			vim.cmd(string.format("highlight Headline%dFg cterm=bold gui=bold guifg=%s", i, heading_colors[i]))
		end

		-- Inline code highlight
		vim.cmd(
			string.format(
				"highlight RenderMarkdownCodeInline guifg=%s guibg=%s gui=bold",
				inline_code_fg,
				inline_code_bg
			)
		)
	end,
	opts = {
		bullet = { enabled = true },
		checkbox = {
			enabled = true,
			position = "inline",
			unchecked = {
				icon = "   󰄱 ",
				highlight = "RenderMarkdownUnchecked",
			},
			checked = {
				icon = "   󰱒 ",
				highlight = "RenderMarkdownChecked",
			},
		},
		html = { enabled = true, comment = { conceal = false } },
		heading = {
			sign = false,
			icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
			backgrounds = {
				"Headline1Bg",
				"Headline2Bg",
				"Headline3Bg",
				"Headline4Bg",
				"Headline5Bg",
				"Headline6Bg",
			},
			foregrounds = {
				"Headline1Fg",
				"Headline2Fg",
				"Headline3Fg",
				"Headline4Fg",
				"Headline5Fg",
				"Headline6Fg",
			},
		},
	},
}
