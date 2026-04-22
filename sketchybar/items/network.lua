local icons = require("icons")
local colors = require("colors")
local settings = require("default")

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

local wifi_up = sbar.add("item", "wifi1", {
	position = "right",
	icon = {
		font = {
			family = settings.default,
			size = 9,
		},
		string = icons.wifi.upload,
	},
	label = {
		font = {
			family = settings.default,
			size = 9,
		},
		color = colors.blue,
		string = "??? Bps",
	},
	y_offset = 4,
})

local wifi_down = sbar.add("item", "wifi2", {
	position = "right",
	icon = {
		font = {
			family = settings.default,
			size = 9,
		},
		string = icons.wifi.download,
	},
	label = {
		font = {
			family = settings.default,
			size = 9,
		},
		color = colors.green,
		string = "??? Bps",
	},
	y_offset = -4,
})

-- Upload network graph
local net_graph_up = sbar.add("graph", "net_graph_up", 42, {
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
	y_offset = 7,
	padding_right = -2,
})

-- History buffers for smoothing and dynamic scaling
local up_history = {}
local down_history = {}

-- how many samples to keep for smoothing
local history_size = 6

-- Convert rate strings like "123 Bps", "12 KBps", "1.2 MBps" into bytes/sec
local function parse_rate(rate_str)
	if not rate_str then
		return 0
	end

	local value, unit = rate_str:match("([%d%.]+)%s*(%a+)")
	value = tonumber(value) or 0

	if not unit then
		return value
	end

	unit = unit:lower()

	if unit:match("kb") then
		return value * 1024
	elseif unit:match("mb") then
		return value * 1024 * 1024
	elseif unit:match("gb") then
		return value * 1024 * 1024 * 1024
	else
		return value
	end
end

net_graph_up:subscribe("network_update", function(env)
	local up = parse_rate(env.upload)

	-- store history
	table.insert(up_history, up)
	if #up_history > history_size then
		table.remove(up_history, 1)
	end

	-- moving average smoothing
	local sum = 0
	for _, v in ipairs(up_history) do
		sum = sum + v
	end
	local avg_up = sum / #up_history

	-- Convert bytes/sec to a log scale based on real network units
	-- 0 = bytes, 1 = KB, 2 = MB, 3 = GB
	local unit_scale = math.log(avg_up + 1) / math.log(1024)

	-- Normalize to graph height where:
	-- ~KB sits low, ~MB sits high
	local normalized = math.min(unit_scale / 3, 1)

	-- small floor so idle traffic still shows movement
	normalized = math.max(normalized, 0.02)

	net_graph_up:push({ normalized })
end)

-- Download network graph
local net_graph_down = sbar.add("graph", "net_graph_down", 42, {
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
	y_offset = -5,
})

local wifi = sbar.add("item", "wifi.status", {
	position = "right",
	padding_right = -2,
	padding_left = -6,
	icon = {
		string = icons.wifi.disconnected,
		font = {
			family = settings.default,
			size = 13.0,
		},
		color = colors.red,
	},
	label = { drawing = false },
})

net_graph_down:subscribe("network_update", function(env)
	local down = parse_rate(env.download)

	-- store history
	table.insert(down_history, down)
	if #down_history > history_size then
		table.remove(down_history, 1)
	end

	-- moving average smoothing
	local sum = 0
	for _, v in ipairs(down_history) do
		sum = sum + v
	end
	local avg_down = sum / #down_history

	-- Convert bytes/sec to a log scale based on real network units
	-- 0 = bytes, 1 = KB, 2 = MB, 3 = GB
	local unit_scale = math.log(avg_down + 1) / math.log(1024)

	-- Normalize to graph height where:
	-- ~KB sits low, ~MB sits high
	local normalized = math.min(unit_scale / 3, 1)

	-- prevent flat idle line
	normalized = math.max(normalized, 0.02)

	net_graph_down:push({ normalized })
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
						icon = { string = icons.wifi.vpn, color = colors.white },
						label = { string = "", color = colors.white },
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
						icon = { string = icons.wifi.ethernet, color = colors.white },
						label = { string = "", color = colors.green },
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
									icon = { string = icons.wifi.hotspot, color = colors.white },
									label = { string = "", color = colors.blue },
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

local wifi_bracket = sbar.add("bracket", "wifi.bracket", {
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
			family = settings.default,
		},
		string = icons.wifi.router,
	},
	width = popup_width,
	align = "center",
	label = {
		font = {
			size = 13,
			family = settings.default,
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
		padding_left = 5,
	},
	label = {
		max_chars = 20,
		string = "????????????",
		width = popup_width / 2,
		align = "right",
		padding_right = 5,
	},
})

local ip = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "IP:",
		width = popup_width / 2,
		padding_left = 5,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
		padding_right = 5,
	},
})

local mask = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "Subnet mask:",
		width = popup_width / 2,
		padding_left = 5,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
		padding_right = 5,
	},
})

local router = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "Router:",
		width = popup_width / 2,
		padding_left = 5,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
		padding_right = 5,
	},
})

local network_interface = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "Network Interface:",
		width = popup_width / 2,
		padding_left = 5,
	},
	label = {
		string = "????",
		width = popup_width / 2,
		align = "right",
		padding_right = 5,
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
	toggle_details()
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

local wifi_up = sbar.add("item", "wifi1", {
	position = "right",
	width = 0,
	icon = {
		font = {
			style = settings.default,
			size = 11,
		},
		string = icons.wifi.upload,
	},
	label = {
		padding_left = 3,
		padding_right = 0,
		font = {
			family = settings.default,
			size = 8,
		},
		color = colors.blue,
		string = "??? Bps",
	},
	y_offset = 8,
})

local wifi_down = sbar.add("item", "wifi2", {
	position = "right",
	icon = {
		font = {
			style = settings.default,
			size = 9,
		},
		string = icons.wifi.download,
	},
	label = {
		padding_left = 3,
		padding_right = 0,
		font = {
			family = settings.default,
			size = 8,
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

	local wifi_click_script =
		'osascript -e \'tell application "System Events" to tell process "ControlCenter" to click menu bar item 3 of menu bar 1 \''
	local shortcut_script =
		'osascript -e \'tell application "System Events" to keystroke "u" using {command down, option down, control down}\''
	local vpn_click_script =
		'osascript -e \'tell application "System Events" to tell process "Passepartout" to click menu bar item 1 of menu bar 2\''
	local little_snitch_click_script = "open -a 'Little Snitch Network Monitor'"

	--	local tailscale_click_script =
	--		'osascript -e \'tell application "System Events" to tell process "Tailscale" to click menu bar item 1 of menu bar 2\''
	--	'osascript -e \'tell application "System Events" to tell process "Little Snitch" to click menu bar item 1 of menu bar 2\''

	-- Wi-Fi item
	wifi:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			toggle_details()
		elseif env.BUTTON == "right" then
			sbar.exec(wifi_click_script)
		else
			sbar.exec(vpn_click_script)
		end
	end)

	-- Wi-Fi up
	wifi_up:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			sbar.exec(shortcut_script)
		elseif env.BUTTON == "right" then
			sbar.exec(little_snitch_click_script)
		end
	end)

	-- Wi-Fi down
	wifi_down:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			sbar.exec(shortcut_script)
		elseif env.BUTTON == "right" then
			sbar.exec(little_snitch_click_script)
		end
	end)

	-- Net graph up
	net_graph_up:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			sbar.exec(shortcut_script)
		elseif env.BUTTON == "right" then
			sbar.exec(little_snitch_click_script)
		end
	end)

	-- Net graph down
	net_graph_down:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			sbar.exec(shortcut_script)
		elseif env.BUTTON == "right" then
			sbar.exec(little_snitch_click_script)
		end
	end)
end)

-- ======== Hover effects ========
local function add_hover(item)
	item:subscribe("mouse.entered", function()
		item:set({
			background = {
				drawing = true,
				color = colors.hover,
				corner_radius = 10,
				height = 30,
				x_offset = 0,
				y_offset = 5,
			},
		})
	end)

	item:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
		item:set({ background = { drawing = false } })
	end)
end

add_hover(wifi_up)
add_hover(wifi_down)

-- ======== Hover effects ========

wifi:subscribe("mouse.entered", function()
	wifi:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 10,
			height = 20,
			x_offset = 1,
			y_offset = 0,
		},
	})
end)

wifi:subscribe("mouse.exited", function()
	wifi:set({ background = { drawing = false } })
end)

net_graph_down:subscribe("mouse.entered", function()
	net_graph_up:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			y_offset = 0,
		},
	})
	net_graph_down:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			x_offset = 0,
		},
	})
end)

net_graph_up:subscribe("mouse.entered", function()
	net_graph_up:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			y_offset = 0,
		},
	})
	net_graph_down:set({
		background = {
			drawing = true,
			color = colors.hover,
			corner_radius = 20,
			height = 10,
			x_offset = 0,
		},
	})
end)

net_graph_down:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	net_graph_up:set({ background = { drawing = true, height = 10, color = colors.transparent } })
	net_graph_down:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)

net_graph_up:subscribe({ "mouse.exited", "mouse.entered.global", "mouse.exited.global" }, function()
	net_graph_down:set({ background = { drawing = true, height = 20, color = colors.transparent } })
	net_graph_up:set({ background = { drawing = true, height = 10, color = colors.transparent } })
end)
