local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the event provider binary which provides the event "network_update"
-- for the current network interface, which is fired every 2.0 seconds.

local function start_network_load()
	sbar.exec("route get default 2>/dev/null | awk '/interface: / {print $2}'", function(iface)
		iface = iface and iface:match("^%s*(.-)%s*$") -- trim whitespace
		if not iface or iface == "" then
			return
		end

		sbar.exec(
			string.format(
				"killall network_load >/dev/null 2>&1; "
					.. "$CONFIG_DIR/helpers/event_providers/network_load/bin/network_load %s network_update 2.0 &",
				iface
			)
		)
	end)
end

-- run immediately at startup
start_network_load()

-- re-run when system wakes or network changes
sbar.add("event", "system_woke"):subscribe("system_woke", start_network_load)
sbar.add("event", "network_change"):subscribe("network_change", start_network_load)

local wifi_up = sbar.add("item", "widgets.wifi1", {
	position = "right",
	icon = {
		font = {
			style = settings.font.style_map["Regular"],
			size = 11.0,
		},
		string = icons.wifi.upload,
	},
	label = {
		font = {
			style = settings.default,
			size = 11.0,
		},
		color = colors.blue,
		string = "??? Bps",
	},
	y_offset = 8,
})

local wifi_down = sbar.add("item", "widgets.wifi2", {
	position = "right",
	icon = {
		font = {
			style = settings.font.style_map["Regular"],
			size = 11.0,
		},
		string = icons.wifi.download,
	},
	label = {
		font = {
			style = settings.default,
			size = 11.0,
		},
		color = colors.green,
		string = "??? Bps",
	},
	y_offset = -4,
})

-- Upload network graph
local net_graph_up = sbar.add("graph", "widgets.net_graph_up", 42, {
	position = "right",
	graph = {
		color = colors.blue,
	},
	background = {
		height = 10,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
	},
	updates = true,
	y_offset = 7,
	padding_right = -2,

	update_freq = 30,
})

local up_history = {}
local down_history = {}
local max_up_history = 1
local max_down_history = 1 -- number of values to average over for download

net_graph_up:subscribe("network_update", function(env)
	local up = tonumber(env.upload:match("%d+")) or 0

	-- add new value to history
	table.insert(up_history, up)
	if #up_history > max_up_history then
		table.remove(up_history, 1)
	end

	-- calculate average
	local sum = 0
	for _, v in ipairs(up_history) do
		sum = sum + v
	end
	local avg_up = sum / #up_history

	-- normalize and push
	net_graph_up:push({ math.min(avg_up / 1000, 1) })
end)

-- Download network graph
local net_graph_down = sbar.add("graph", "widgets.net_graph_down", 42, {
	position = "right",
	padding_right = -49,
	graph = {
		color = colors.green,
	},
	background = {
		height = 10,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
	},
	updates = true,
	y_offset = -5,
	update_freq = 30,
})

local wifi = sbar.add("item", "wifi.status", {
	position = "right",
	padding_right = -2,
	padding_left = 2,
	icon = {
		string = icons.wifi.disconnected,
		font = {
			style = settings.default,
			size = 14.0,
		},
		color = colors.red,
	},
	label = { drawing = false },
})

net_graph_down:subscribe("network_update", function(env)
	local down = tonumber(env.download:match("%d+")) or 0

	-- add new value to history
	table.insert(down_history, down)
	if #down_history > max_down_history then
		table.remove(down_history, 1)
	end

	-- calculate average
	local sum = 0
	for _, v in ipairs(down_history) do
		sum = sum + v
	end
	local avg_down = sum / #down_history

	-- normalize and push
	net_graph_down:push({ math.min(avg_down / 1000, 1) })
end)

-- updates wifi logo based on conditions (connected, disconnected, vpn, ethernet)

local function updateNetworkStatus()
	-- 1. First check if ANY interface has internet
	sbar.exec("ping -c1 -t1 8.8.8.8 >/dev/null 2>&1 && echo 1 || echo 0", function(hasInternet)
		-- 2. Check VPN status (parallel check since it's independent)
		sbar.exec("scutil --nc list | grep -q Connected && echo 1 || echo 0", function(vpnStatus)
			-- 3. Check active interface (only if needed)
			sbar.exec("route get default 2>/dev/null | awk '/interface: / {print $2}'", function(activeInterface)
				-- Visual feedback logic
				if tonumber(vpnStatus) == 1 then
					-- VPN ACTIVE (highest priority)
					wifi:set({
						icon = { string = "􀎡", color = colors.white },
						label = { string = "VPN", color = colors.white },
					})
				elseif tonumber(hasInternet) == 0 then
					-- DISCONNECTED
					wifi:set({
						icon = { string = icons.wifi.disconnected, color = colors.red },
						label = { drawing = false },
					})
				elseif activeInterface and tonumber(activeInterface:match("^en(%d+)")) >= 1 then
					-- ETHERNET
					wifi:set({
						icon = { string = "􀤆", color = colors.white },
						label = { string = "Ethernet", color = colors.green },
					})
				else
					-- WIFI/HOTSPOT CHECK using system_profiler
					sbar.exec(
						"networksetup -listpreferredwirelessnetworks en0 | sed -n '2p' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'",
						function(ssid_result)
							local ssid_str = ssid_result or ""
							if ssid_str:match("iPhone") then
								-- Detected hotspot
								wifi:set({
									icon = { string = "􀉤", color = colors.white },
									label = { string = "Hotspot", color = colors.blue },
								})
							else
								-- Normal Wi-Fi
								wifi:set({
									icon = { string = icons.wifi.connected, color = colors.white },
									label = { drawing = false },
								})
							end
						end
					)
				end
			end)
		end)
	end)
end

-- Initial update with 1s delay to allow network stabilization
sbar.delay(1, updateNetworkStatus)

-- Event subscriptions
wifi:subscribe({ "wifi_change", "system_woke", "network_update", "vpn_state_change" }, function()
	sbar.delay(0.5, updateNetworkStatus)
end)

local popup_width = 250

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
		padding_right = 5,
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
		sbar.exec(
			"networksetup -listpreferredwirelessnetworks en0 | sed -n '2p' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'",
			function(result)
				ssid:set({ label = result })
			end,
			sbar.exec(
				"networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'",
				function(result)
					mask:set({ label = result })
				end
			),
			sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
				router:set({ label = result })
			end),
			sbar.exec("route get default | awk '/interface: / {print $2}'", function(result)
				network_interface:set({ label = result })
			end)
		)
	else
		wifi_bracket:set({ popup = { drawing = false } })
	end
end

wifi:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.exited.global", function()
	wifi_bracket:set({ popup = { drawing = false } })
end)

wifi_up:subscribe("network_update", function(env)
	local upload_str = env.upload:gsub("Bps", "B/s")
	local download_str = env.download:gsub("Bps", "B/s")

	local up_color = (upload_str == "000 B/s") and colors.grey or colors.blue
	local down_color = (download_str == "000 B/s") and colors.grey or colors.green

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

-- Initial update with 1s delay to allow network stabilization
sbar.delay(1, updateNetworkStatus)

-- Event subscriptions
wifi:subscribe({ "wifi_change", "system_woke", "network_update", "vpn_state_change" }, function()
	sbar.delay(1, updateNetworkStatus)
end)

local wifi_up = sbar.add("item", "widgets.wifi1", {
	position = "right",
	width = 0,
	icon = {
		font = {
			style = settings.font.style_map["Bold"],
			size = 11.0,
		},
		string = icons.wifi.upload,
	},
	label = {
		padding_left = 3,
		padding_right = 0,
		font = {
			style = settings.default,
			size = 11.0,
		},
		color = colors.blue,
		string = "??? Bps",
	},
	y_offset = 8,
})

local wifi_down = sbar.add("item", "widgets.wifi2", {
	position = "right",
	icon = {
		font = {
			style = settings.font.style_map["Regular"],
			size = 11.0,
		},
		string = icons.wifi.download,
	},
	label = {
		padding_left = 3,
		padding_right = 0,
		font = {
			style = settings.default,
			size = 11.0,
		},
		color = colors.green,
		string = "??? Bps",
	},
	y_offset = -4,
})

wifi_up:subscribe("network_update", function(env)
	local upload_str = env.upload:gsub("Bps", "B/s")
	local download_str = env.download:gsub("Bps", "B/s")

	local up_color = (upload_str == "000 B/s") and colors.grey or colors.blue
	local down_color = (download_str == "000 B/s") and colors.grey or colors.green

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

	-- your working Wi-Fi click AppleScript
	local wifi_click_script =
		'osascript -e \'tell application "System Events" to tell process "ControlCenter" to click menu bar item 4 of menu bar 1\''

	-- keyboard shortcut command (Cmd+Opt+Ctrl+N)
	local shortcut_script =
		'osascript -e \'tell application "System Events" to keystroke "n" using {command down, option down, control down}\''
	local vpn_click_script =
		'osascript -e \'tell application "System Events" to tell process "Passepartout" to click menu bar item 1 of menu bar 2\''

	-- Wi-Fi item
	wifi:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			toggle_details()
		elseif env.BUTTON == "right" then
			sbar.exec(vpn_click_script)
		end
	end)

	-- Wi-Fi up
	wifi_up:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			sbar.exec(shortcut_script)
		elseif env.BUTTON == "right" then
			sbar.exec(wifi_click_script)
		end
	end)

	-- Wi-Fi down
	wifi_down:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			sbar.exec(shortcut_script)
		elseif env.BUTTON == "right" then
			sbar.exec(wifi_click_script)
		end
	end)

	-- Net graph up
	net_graph_up:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			sbar.exec(shortcut_script)
		elseif env.BUTTON == "right" then
			sbar.exec(wifi_click_script)
		end
	end)

	-- Net graph down
	net_graph_down:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			sbar.exec(shortcut_script)
		elseif env.BUTTON == "right" then
			sbar.exec(wifi_click_script)
		end
	end)
end)
