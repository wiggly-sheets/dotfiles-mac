# YabaiGridSpaces spoon

## Installation

Download `YabaiGridSpaces.spoon.zip` from <https://github.com/mikkelricky/hammerspoon/releases> and extract it.

Load and configure the `YabaiGridSpaces` spoon in `~/.hammerspoon/init.lua`:

``` lua
hs.loadSpoon("YabaiGridSpaces")
spoon.YabaiGridSpaces
  :applyConfig({
    numberOfColumns = 3,
  })
  :bindHotKeys({
    -- https://www.hammerspoon.org/docs/hs.hotkey.html
    navigateNorth = {{"cmd", "ctrl"}, "up"},
    navigateEast = {{"cmd", "ctrl"}, "right"},
    navigateSouth = {{"cmd", "ctrl"}, "down"},
    navigateWest = {{"cmd", "ctrl"}, "left"},
  })
  :start()
```

[Reload your Hammerspoon config](https://www.hammerspoon.org/go/#simplereload).
