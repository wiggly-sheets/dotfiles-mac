local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the event provider binary which provides the event "network_update"
-- for the current network interface, which is fired every 2.0 seconds.
sbar.exec(
	"killall network_load >/dev/null; $CONFIG_DIR/helpers/event_providers/network_load/bin/network_load en0 network_update 2.0"
)

local popup_width = 250

local sbar = require("sketchybar")
local icons = require("icons")
local colors = require("colors")

local wifi = sbar.add("item", "wifi.status", {
	position = "right",
	icon = {
		string = icons.wifi.disconnected,
		font = {
			family = "IosevkaTermSlab Nerd Font",
			size = 15.0,
		},
		color = colors.red,
	},
	label = { drawing = false },
	padding_left = -5,
	padding_right = 5,
})

wifi:subscribe({ "wifi_change", "system_woke" }, function()
	sbar.exec("ipconfig getifaddr en0", function(ip)
		if ip == "" then
			wifi:set({
				icon = {
					string = icons.wifi.disconnected,
					color = colors.red,
				},
			})
		else
			wifi:set({
				icon = {
					string = icons.wifi.connected,
					color = colors.white,
				},
			})
		end
	end)
end)

local wifi_up = sbar.add("item", "widgets.wifi1", {
	position = "right",
	padding_left = 0,
	width = 0,
	icon = {
		padding_right = 0,
		font = {
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		string = icons.wifi.upload,
	},
	label = {
		font = {
			family = "IosevkaTermSlab Nerd Font Mono",
			style = settings.font.style_map["Medium"],
			size = 9.0,
		},
		color = colors.red,
		string = "??? Bps",
	},
	y_offset = 8,
	click_script = "cliclick kd:cmd,alt,shift,ctrl t:=",
})

local wifi_down = sbar.add("item", "widgets.wifi2", {
	position = "right",
	padding_left = -5,
	icon = {
		padding_right = 0,
		font = {
			style = settings.font.style_map["Regular"],
			size = 9.0,
		},
		string = icons.wifi.download,
	},
	label = {
		font = {
			family = "IosevkaTermSlab Nerd Font Mono",
			style = settings.font.style_map["Regular"],
			size = 9.0,
		},
		color = colors.blue,
		string = "??? Bps",
	},
	y_offset = -4,
	click_script = [[cliclick kd:cmd,alt,ctrl,shift t:=]],
})

local wifi_padding = sbar.add("item", "widgets.wifi.padding", {
	position = "right",
	label = { drawing = false },
})

local wifi_bracket = sbar.add("bracket", "widgets.wifi.bracket", {
	wifi.name,
	wifi_up.name,
	wifi_down.name,
}, {
	background = { color = colors.bg1 },
	popup = { align = "center", height = 30 },
})

local ssid = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		font = {
			style = settings.font.style_map["Bold"],
		},
		string = icons.wifi.router,
	},
	width = popup_width,
	align = "center",
	label = {
		font = {
			size = 15,
			style = settings.font.style_map["Bold"],
		},
		max_chars = 18,
		string = "????????????",
	},
	background = {
		height = 2,
		color = colors.grey,
		y_offset = -15,
	},
})

local hostname = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "Hostname:",
		width = popup_width / 2,
	},
	label = {
		max_chars = 20,
		string = "????????????",
		width = popup_width / 2,
		align = "right",
	},
})

local ip = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "IP:",
		width = popup_width / 2,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
	},
})

local mask = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "Subnet mask:",
		width = popup_width / 2,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
	},
})

local router = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "Router:",
		width = popup_width / 2,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
	},
})

local network_interface = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "Network Interface:",
		width = popup_width / 2,
	},
	label = {
		string = "????",
		width = popup_width / 2,
		align = "right",
	},
})

local function toggle_details()
	local should_draw = wifi_bracket:query().popup.drawing == "off"
	if should_draw then
		wifi_bracket:set({ popup = { drawing = true } })
		sbar.exec("networksetup -getcomputername", function(result)
			hostname:set({ label = result })
		end)
		sbar.exec("ipconfig getifaddr en0", function(result)
			ip:set({ label = result })
		end)
		sbar.exec("ipconfig getsummary en0 | awk -F ' SSID : '  '/ SSID : / {print $2}'", function(result)
			ssid:set({ label = result })
		end)
		sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'", function(result)
			mask:set({ label = result })
		end)
		sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
			router:set({ label = result })
		end)
		sbar.exec("route get default | awk '/interface: / {print $2}'", function(result)
			network_interface:set({ label = result })
		end)
	else
		wifi_bracket:set({ popup = { drawing = false } })
	end
end

--wifi_up:subscribe("mouse.clicked", toggle_details)
--wifi_down:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.exited.global", function()
	wifi_bracket:set({ popup = { drawing = false } })
end)
wifi_up:subscribe("network_update", function(env)
	-- Replace "Bps" with "B/s" in the upload and download strings.
	local upload_str = env.upload:gsub("Bps", "B/s")
	local download_str = env.download:gsub("Bps", "B/s")

	local up_color = (upload_str == "000 B/s") and colors.grey or colors.red
	local down_color = (download_str == "000 B/s") and colors.grey or colors.blue

	wifi_up:set({
		icon = { color = up_color },
		label = {
			string = upload_str,
			color = up_color,
		},
	})

	wifi_down:set({
		icon = { color = down_color },
		label = {
			string = download_str,
			color = down_color,
		},
	})
end)
