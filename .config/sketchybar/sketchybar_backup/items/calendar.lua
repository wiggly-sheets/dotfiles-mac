local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })



local cal_up = sbar.add("item", {
    position = "right",
    padding_left = 0,
    padding_right = 15,
    width = 0,
    label = {
      color = colors.white,
      font = {
        family = settings.font.numbers,
        size = 11.0
      }
      
    },
    y_offset = 6,
    x_offset = -30,
  })

local cal_down = sbar.add("item", {
    position = "right",
    padding_left = 0,
    padding_right = 25,
    y_offset = -6,
    x_offset = -30,
    label = {
      color = colors.white,
      font = {
        family = settings.font.numbers,
        size = 11.0
      }
    },
 
  })

-- Add the calendar icon to the right side, next to the date and time
sbar.add("item", {
  name = "calendar_icon",
  position = "right",
  icon = {
    string = "􀉉", -- SF Symbol for calendar
    font = { style = "Bold", size = 15.0 },
  },
  padding_left = -5, -- Add spacing between the icon and the time
  padding_right = -10, -- Add spacing to the right of the icon
  y_offset = -0
  
})

-- Double border for calendar using a single item bracket
local cal_bracket = sbar.add("bracket", { cal_up.name, cal_down.name }, {
  background = {
    color = colors.transparent,
    height = 30,
    border_color = colors.grey
  },
  update_freq = 1
})

-- Padding item required because of bracket
local spacing = sbar.add("item", { position = "right", width = 26 })

cal_bracket:subscribe({ "forced", "routine", "system_woke" }, function(env)
    local up_value = string.format("%s %d", os.date("%a %b %d"), tonumber(os.date("%Y")))
    if #up_value < 10 then
      spacing:set({ width = 18 })
    end
    local down_value = string.format("%d:%s", tonumber(os.date("%H")), os.date("%M:%S %Z"))
    cal_up:set({ label = { string = up_value } })
    cal_down:set({ label = { string = down_value } })
  end)

local function click_event(env)
  sbar.exec(settings.calendar.click_script)
end

cal_up:subscribe("mouse.clicked", click_event)
cal_down:subscribe("mouse.clicked", click_event)
