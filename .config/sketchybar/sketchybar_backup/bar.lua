local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
  height = 40,
  corner_radius = 6,
  color = colors.bar.bg,
  padding_right = 10,
  padding_left = 10,
  border_color = colors.white,
  border_width = 1,
  topmost = "window"
})
