-- SketchyBar Lua script to show CPU and GPU temperatures

local colors = require("colors")
local settings = require("settings")

-- Create the temperature widget
local temp_widget = sbar.add("item", "widgets.temperature", {
  position = "right",
  icon = {
    string = "🌡", -- Custom icon for the temperature widget
    font = {
      style = settings.font.style_map["Regular"],
      size = 14.0,
    },
    color = colors.blue, -- Default color for the icon
  },
  label = {
    string = "??°C", -- Placeholder for temperature
    font = {
      family = settings.font.numbers,
    },
    color = colors.blue, -- Default color for the label
  },
  update_freq = 10, -- Update every 10 seconds
  padding_right = -10,
  padding_left = -10,
  popup = { align = "center" },
})

-- Function to fetch CPU temperature (works on macOS)
local function fetch_cpu_temp()
  sbar.exec("sysctl -n machdep.xcpm.cpu_thermal_level", function(output)
    local cpu_temp_value = tonumber(output)
    if cpu_temp_value then
      cpu_temp_value = cpu_temp_value / 10 -- Convert to degrees Celsius
      temp_widget:set({ label = string.format("%.1f°C", cpu_temp_value) })
    else
      temp_widget:set({ label = "N/A" })
    end
  end)
end

-- Function to fetch GPU temperature (works on macOS with Apple Silicon)
local function fetch_gpu_temp()
  sbar.exec("sysctl -n machdep.xcpm.gpu_thermal_level", function(output)
    local gpu_temp_value = tonumber(output)
    if gpu_temp_value then
      gpu_temp_value = gpu_temp_value / 10 -- Convert to degrees Celsius
      temp_widget:set({ label = string.format("%.1f°C", gpu_temp_value) })
    else
      temp_widget:set({ label = "N/A" })
    end
  end)
end

-- Update the widget with CPU and GPU temperatures
temp_widget:subscribe("routine", function()
  fetch_cpu_temp()
  fetch_gpu_temp()
end)

-- Add padding space
sbar.add("item", "widgets.temperature.padding", {
  position = "right",
  width = settings.group_paddings,
})
