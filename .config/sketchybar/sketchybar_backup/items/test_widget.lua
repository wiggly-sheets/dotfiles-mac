
local colors = require("colors")

local test_widget = sbar.add("item", "widgets.test", {
  position = "right",
  icon = {
    string = "✅",
    color = colors.green,
  },
  label = {
    string = "Test",
    color = colors.green,
  },
})

test_widget:subscribe("mouse.clicked", function()
  test_widget:set({ label = "Clicked!" })
end)
