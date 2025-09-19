return {
	"goolord/alpha-nvim",
	event = "VimEnter",
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")

		-- Set header
		dashboard.section.header.val = {

			[[                                                                         ]],
			[[                               :                                         ]],
			[[ L.                     ,;    t#,                                        ]],
			[[ EW:        ,ft       f#i    ;##W.              t                        ]],
			[[ E##;       t#E     .E#t    :#L:WE              Ej            ..       : ]],
			[[ E###t      t#E    i#W,    .KG  ,#D  t      .DD.E#,          ,W,     .Et ]],
			[[ E#fE#f     t#E   L#D.     EE    ;#f EK:   ,WK. E#t         t##,    ,W#t ]],
			[[ E#t D#G    t#E :K#Wfff;  f#.     t#iE#t  i#D   E#t        L###,   j###t ]],
			[[ E#t  f#E.  t#E i##WLLLLt :#G     GK E#t j#f    E#t      .E#j##,  G#fE#t ]],
			[[ E#t   t#K: t#E  .E#L      ;#L   LW. E#tL#i     E#t     ;WW; ##,:K#i E#t ]],
			[[ E#t    ;#W,t#E    f#E:     t#f f#:  E#WW,      E#t    j#E.  ##f#W,  E#t ]],
			[[ E#t     :K#D#E     ,WW;     f#D#;   E#K:       E#t  .D#L    ###K:   E#t ]],
			[[ E#t      .E##E      .D#;     G#t    ED.        E#t :K#t     ##D.    E#t ]],
			[[ ..         G#E        tt      t     t          E#t ...      #G      ..  ]],
			[[             fE                                 ,;.          j           ]],
			[[              ,                                                          ]],
			[[                                                                         ]],

			"           __                                ",
			".-.__      \\ .-.  ___  __                    ",
			"|_|  '--.-.-(   \\/\\;;\\_\\.-._______.-.        ",
			"(-)___     \\ \\ .-\\ \\;;\\(   \\       \\ \\       ",
			" Y    '---._\\_((Q)) \\;;\\\\ .-\\     __(_)      ",
			" I           __'-' / .--.((Q))---'    \\,     ",
			" I     ___.-:    \\|  |   \\'-'_          \\    ",
			" A  .-'      \\ .-.\\   \\   \\ \\ '--.__     '\\  ",
			" |  |____.----((Q))\\   \\__|--\\_      \\     ' ",
			"    ( )        '-'  \\_  :  \\-' '--.___\\      ",
			"     Y                \\  \\  \\       \\(_)     ",
			"     I                 \\  \\  \\         \\,    ",
			"     I                  \\  \\  \\          \\   ",
			"     A                   \\  \\  \\          '\\ ",
			"     |                    \\  \\__|           '",
			"                           \\_:.  \\           ",
			"                             \\ \\  \\          ",
			"                              \\ \\  \\         ",
			"                               \\_\\_|         ",
		}

		--  "                                                     ",
		--"  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
		--"  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
		--"  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
		--"  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
		--"  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ █║ ",
		--"  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
		-- "                                                     ",
		-- }

		-- Set menu
		dashboard.section.buttons.val = {
			dashboard.button("e", "  > New File", "<cmd>ene<CR>"),
			dashboard.button("SPC ee", "  > Toggle file explorer", "<cmd>NvimTreeToggle<CR>"),
			dashboard.button("SPC ff", "󰱼 > Find File", "<cmd>Telescope find_files<CR>"),
			dashboard.button("SPC fs", "  > Find Word", "<cmd>Telescope live_grep<CR>"),
			dashboard.button("SPC wr", "󰁯  > Restore Session For Current Directory", "<cmd>SessionRestore<CR>"),
			dashboard.button("q", " > Quit NVIM", "<cmd>qa<CR>"),
		}

		-- Send config to alpha
		alpha.setup(dashboard.opts)

		-- Disable folding on alpha buffer
		vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
	end,
}
