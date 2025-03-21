local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Low Power Mode Widget --
local lowpowermode = sbar.add("item", "widgets.lowpowermode", {
    position = "right",
    label = {
        font = {
            family = "SF Symbols",
            size = 20.0
        },
        string = "⚡︎",
        color = colors.red,
        padding_right = 0,
        padding_left = -10
    }
})

local function setModeValue(v)
    local color = v == 1 and colors.green or colors.red
    lowpowermode:set({ label = { string = "⚡︎", color = color } })
    sbar.exec("sudo pmset -a lowpowermode " .. (v == 1 and "1" or "0"), function() end)
end

lowpowermode:subscribe({ "power_source_change", "system_woke" }, function()
    sbar.exec("pmset -g | grep lowpowermode", function(mode_info)
        local found, _, enabled = mode_info:find("(%d+)")
        if found then setModeValue(tonumber(enabled)) end
    end)
end)

lowpowermode:subscribe("mouse.clicked", function()
    setModeValue(lowpowermode:query().label.color == colors.red and 1 or 0)
end)

sbar.add("bracket", "widgets.lowpowermode.bracket", { lowpowermode.name }, {
    background = { color = colors.bg1 }
})

sbar.add("item", "widgets.lowpowermode.padding", {
    position = "right",
    width = 5
})

-- Battery Widget --
local battery = sbar.add("item", "widgets.battery", {
    position = "right",
    icon = {
        font = { style = settings.font.style_map["Regular"] },
        color = colors.green,
        padding_right = -1
    },
    padding_left = 4,
    padding_right = -5,
    label = {
        font = { family = settings.font.numbers },
        color = colors.green,
        size = 20.0
    },
    update_freq = 60,
    popup = { align = "center" }
})

-- Single Instance Popup Items --
local popup_items = {
    time = sbar.add("item", {
        position = "popup." .. battery.name,
        icon = { string = "Time:", width = 100, align = "left" },
        label = { string = "Calculating...", width = 100, align = "right" }
    }),
    capacity = sbar.add("item", {
        position = "popup." .. battery.name,
        icon = { string = "Capacity:", width = 100, align = "left" },
        label = { string = "86%", width = 100, align = "right" }
    }),
    condition = sbar.add("item", {
        position = "popup." .. battery.name,
        icon = { string = "Condition:", width = 100, align = "left" },
        label = { string = "Normal", width = 100, align = "right" }
    }),
    power_mode = sbar.add("item", {
        position = "popup." .. battery.name,
        icon = { string = "Low Power:", width = 100, align = "left" },
        label = { string = "Disabled", width = 100, align = "right" }
    }),
    usage = sbar.add("item", {
        position = "popup." .. battery.name,
        icon = { string = "Usage:", width = 100, align = "left" },
        label = { string = "N/A", width = 100, align = "right" }
    })
}

-- Battery Updates --
local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Battery Updates --
local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Battery Updates --
battery:subscribe({ "routine", "power_source_change", "system_woke" }, function()
    sbar.exec("pmset -g batt", function(batt_info)
        local icon = "!"
        local label = "?"
        local color = colors.green
        local charging = batt_info:find("AC Power")
        
        local found, _, charge = batt_info:find("(%d+)%%")
        if found then
            charge = tonumber(charge)
            label = charge .. "%"
            icon = charge > 80 and icons.battery._100
                or charge > 60 and icons.battery._75
                or charge > 40 and icons.battery._50
                or charge > 20 and icons.battery._25
                or icons.battery._0
            color = charge > 20 and colors.green or charge > 10 and colors.orange or colors.red
        end

        -- Extract battery time remaining
        local time_remaining = "Calculating..."
        local time_match = batt_info:match("(%d+:%d+) remaining")
        local charging_match = batt_info:match("until fully charged")

        if time_match then
            time_remaining = time_match .. " remaining"
        elseif charging_match then
            time_remaining = "Until full"
        end

        battery:set({
            icon = { string = charging and icons.battery.charging or icon, color = color },
            label = { string = (found and charge < 10 and "0" or "") .. label, color = color }
        })

        -- Update time remaining in popup
        popup_items.time:set({ label = time_remaining })
    end)

    -- Extract battery capacity
    sbar.exec("system_profiler SPPowerDataType | grep 'Maximum Capacity' | awk '{print $3}'", function(capacity)
        local cap = capacity and capacity:match("%d+") or "N/A"
        popup_items.capacity:set({ label = cap .. "%" })
    end)
end)


-- Popup Interactions --
battery:subscribe("mouse.clicked", function(env)
    local drawing = battery:query().popup.drawing
    battery:set({ popup = { drawing = drawing == "off" and "on" or "off" } })

    if drawing == "off" then
     sbar.exec([[
    voltage=$(ioreg -rc AppleSmartBattery | grep -i Voltage | grep -v '{' | awk '{print $3}' | tr -d ,)
    amperage=$(ioreg -rc AppleSmartBattery | grep -i Amperage | grep -v '{' | awk '{print $3}' | tr -d ,)
    
    if [ -z "$voltage" ] || [ -z "$amperage" ] || [ "$voltage" -eq 0 ] || [ "$amperage" -eq 0 ]; then
        echo "N/A"
    else
        printf "%.2f W" $(echo "scale=2; ($voltage * $amperage) / 1000000" | bc -l)
    fi
]], function(watts)
    popup_items.usage:set({ label = watts and watts:match("%d") and watts:gsub("%s+", "") or "N/A" })
end)  
  end
end)


battery:subscribe("mouse.exited.global", function()
    battery:set({ popup = { drawing = "off" } })
end)

sbar.add("bracket", "widgets.battery.bracket", { battery.name }, {
    background = { color = colors.bg1 }
})

sbar.add("item", "widgets.battery.padding", {
    position = "right",
    width = settings.group_paddings
})