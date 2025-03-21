local lowpowermode = sbar.add("item", "widgets.lowpowermoe", {
  position = "right",
  label = { 
    icon = {
      string = "⚡",  -- Electric bolt icon
      color = colors.red,  -- Default color is red (low power mode disabled)
      padding_right = 3
    },
    font = {
      family = "Helvetica",  -- Or any font that works with your system
      style = "bold",  -- Making the icon bold to emphasize
      size = 22.0  -- You can adjust the size to your preference
    }
  },
})

-- Function to update the color of the icon based on low power mode status
local function updateLowPowerModeColor(isLowPowerMode)
  local iconColor = isLowPowerMode and colors.green or colors.red  -- Green for enabled, Red for disabled
  lowpowermode:set({
    label = {
      icon = {
        color = iconColor  -- Change icon color dynamically
      }
    }
  })
end

-- Listen to system power status changes to adjust the icon color
lowpowermode:subscribe({"power_source_change", "system_woke"}, function(env)
  sbar.exec("pmset -g |grep lowpowermode", function(mode_info)
    local found, _, enabled = mode_info:find("(%d+)")
    if found then
      local isLowPowerMode = tonumber(enabled) == 1
      updateLowPowerModeColor(isLowPowerMode)  -- Update color based on current mode
    end
  end)
end)

-- Toggle between low power mode states when clicked
lowpowermode:subscribe("mouse.clicked", function(env)
  sbar.exec("pmset -g batt", function(batt_info)
    local currentMode = batt_info:find("Low Power Mode:.*(1|0)")
    local isLowPowerMode = currentMode and currentMode:match("(%d)") == "1"
    -- Toggle the mode and update color
    if isLowPowerMode then
      sbar.exec("sudo pmset -a lowpowermode 0", function() end)  -- Disable
    else
      sbar.exec("sudo pmset -a lowpowermode 1", function() end)  -- Enable
    end
    updateLowPowerModeColor(not isLowPowerMode)  -- Update color after toggling
  end)
end)

-- Add bracket and padding (unchanged from previous)
sbar.add("bracket", "widgets.lowpowermode.bracket", { lowpowermode.name }, {
  background = { color = colors.bg1 },
})

sbar.add("item", "widgets.lowpowermode.padding", {
  position = "right",
  width = 5,
})
