local settings = require("settings")

local icons = {
	sf_symbols = {
		loading = "􀖇",
		apple = "􀣺",
		gear = "􀍟",
		cpu = "􀫥",
		clipboard = "􀉄",
		clipboard_list = "􁕜",
		dnd_on = "􀆺", -- Unicode or custom symbol for DND ON
		dnd_off = "􀆹", -- Unicode or custom symbol for DND OFF
		restart = "􀚁",
		ram = "􀫦",
		calendar = "􀉉",
		music = "􀑪",
		Books = "􀤟",
		weather = {
			sunny = "􀆭",
			partly = "􀇔",
			cloudy = "􀇂",
			rainy = "􀇆",
			snowy = "􀇎",
			clear = "􀇀",
			foggy = "􀇊",
			stormy = "􀇞",
			sleet = "􀇐",
		},
		mic = {
			muted = "􀊳",
			on = "􀊱",
		},
		stocks = {
			up = "􀄤",
			down = "􀄥",
			even = "􀂓",
		},
		switch = {
			on = "􁏮",
			off = "􁏯",
		},
		volume = {
			_100 = "􀊩",
			_66 = "􀊧",
			_33 = "􀊥",
			_10 = "􀊡",
			_0 = "􀊣",
		},
		battery = {
			_100 = "􀛨",
			_75 = "􀺸",
			_50 = "􀺶",
			_25 = "􀛩",
			_0 = "􀛪",
			charging = "􀢋",
		},
		wifi = {
			upload = "􀄨",
			download = "􀄩",
			connected = "􀙇",
			disconnected = "􀙈",
			router = "􁓤",
			vpn = "􀒲",
		},
		media = {
			back = "􀊊",
			forward = "􀊌",
			play_pause = "􀊈",
			play = "􀊄",
			pause = "􀊆",
		},
	},

	-- Alternative NerdFont icons
	nerdfont = {
		plus = "",
		loading = "",
		apple = "",
		gear = "",
		cpu = "",
		clipboard = "Missing Icon",

		switch = {
			on = "󱨥",
			off = "󱨦",
		},
		volume = {
			_100 = "",
			_66 = "",
			_33 = "",
			_10 = "",
			_0 = "",
		},
		battery = {
			_100 = "",
			_75 = "",
			_50 = "",
			_25 = "",
			_0 = "",
			charging = "",
		},
		wifi = {
			upload = "",
			download = "",
			connected = "󰖩",
			disconnected = "󰖪",
			router = "Missing Icon",
		},
		media = {
			back = "",
			forward = "",
			play_pause = "",
		},
	},
}

if not (settings.icons == "NerdFont") then
	return icons.sf_symbols
else
	return icons.nerdfont
end
