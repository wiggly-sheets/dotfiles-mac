local icons = require("helpers.icons")
local colors = require("colors")
local settings = require("default")

local network = sbar.add("item", "network.status", {
	position = "right",
	padding_right = 0,
	padding_left = 2,
	icon = {
		string = icons.wifi.disconnected,
		font = {
			family = settings.default,
			size = 13.0,
		},
		color = colors.red,
	},
	label = { drawing = false },})

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
					network:set({
						icon = { string = icons.wifi.vpn, color = colors.white },
						label = { string = "", color = colors.white },
					})
				elseif tonumber(hasInternet) == 0 then
					-- DISCONNECTED
					network:set({
						icon = { string = icons.wifi.disconnected, color = colors.red },
						label = { drawing = false },
					})
				elseif activeInterface and tonumber(activeInterface:match("^en(%d+)")) >= 1 then
					-- ETHERNET
					network:set({
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
								network:set({
									icon = { string = icons.wifi.hotspot, color = colors.white },
									label = { string = "", color = colors.blue },
								})
							else
								-- Normal Wi-Fi
								network:set({
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
network:subscribe({ "wifi_change", "system_woke", "network_update", "vpn_state_change" }, function()
	sbar.delay(0.5, updateNetworkStatus)
end)

local popup_width = 250

local network_bracket = sbar.add("bracket", "network.bracket", {
	network.name,
	
}, {
	background = { color = colors.bg1 },
	popup = { align = "center", height = 30 },
})

local ssid = sbar.add("item", {
	position = "popup." .. network_bracket.name,
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
	position = "popup." .. network_bracket.name,
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
	position = "popup." .. network_bracket.name,
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
	position = "popup." .. network_bracket.name,
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
	position = "popup." .. network_bracket.name,
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
	position = "popup." .. network_bracket.name,
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
	local should_draw = network_bracket:query().popup.drawing == "off"
	if should_draw then
		network_bracket:set({ popup = { drawing = true } })
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
		network_bracket:set({ popup = { drawing = false } })
	end
end

network:subscribe("mouse.clicked", toggle_details)

network:subscribe("mouse.exited", function()
	toggle_details()
end)



local network_click_script =
	'osascript -e \'tell application "System Events" to tell process "ControlCenter" to click menu bar item 3 of menu bar 1 \''

local vpn_click_script =
	'osascript -e \'tell application "System Events" to tell process "Passepartout" to click menu bar item 1 of menu bar 2\''

	network:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		toggle_details()
	elseif env.BUTTON == "right" then
		sbar.exec(network_click_script)
	else
		sbar.exec(vpn_click_script)
	end
end)

network:subscribe("mouse.entered", function()
	network:set({
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

network:subscribe("mouse.exited", function()
	network:set({ background = { drawing = false } })
end)


