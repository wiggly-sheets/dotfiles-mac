local sbar = require("sketchybar")
-- register events
sbar.add("event", "lock", "com.apple.screenIsLocked")
sbar.add("event", "unlock", "com.apple.screenIsUnlocked")

-- create animator item AND keep a reference
local animator = sbar.add("item", "animator", {
  position = "center",
  drawing = false,
  updates = true,
})

local function lock()
  sbar.bar({
    y_offset = -32,
    margin = -200,
    notch_width = 0,
    blur_radius = 0,
  })
end

local function unlock()
  sbar.animate("sin", 25, function()
    sbar.bar({
      y_offset = 0,
      notch_width = 200,
      margin = 0,
      shadow = "off",
      corner_radius = 0,
      blur_radius = 0,
    })
  end)
end

-- subscribe with per-event handlers
animator:subscribe("lock", function()
  lock()
end)

animator:subscribe("unlock", "forced", function()
  unlock()
end)
