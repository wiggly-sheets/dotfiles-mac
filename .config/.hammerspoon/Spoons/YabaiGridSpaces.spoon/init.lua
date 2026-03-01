--- === YabaiGridSpaces ===
---
--- Yabai Grid Spaces spoon.
---
--- Download: <http://github.com/mikkelricky/hammerspoon/raw/main/Spoons/YabaiGridSpaces.spoon.zip>

require("hs.fnutils")

local NORTH <const> = "north"
local EAST <const> = "east"
local SOUTH <const> = "south"
local WEST <const> = "west"

local screen = require("hs.screen")
local canvas = require("hs.canvas")

local debug = function(v)
  hs.alert(hs.json.encode(v, true))
end

local YabaiGridSpaces = {
  -- Metadata
  name = "YabaiGridSpaces",
  version = "1.0",
  author = "Mikkel Ricky <mikkel@mikkelricky.dk>",
  homepage = "http://github.com/mikkelricky/hammerspoon",
  license = "MIT - https://opensource.org/licenses/MIT",
}

-- GridSpaces configuration
local yabaiPath = "/usr/local/bin/yabai"
local numberOfColumns = 3
local gridDisplayTimeout = 0.75
local gridScale = 0.05
local wrapAround = false

--- YabaiGridSpaces:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for YabaiGridSpaces
---
--- Parameters:
---  * config - A table containing config:
---   * reloadConfiguration - This will cause the configuration to be reloaded
function YabaiGridSpaces:applyConfig(config)
  yabaiPath = config.yabaiPath
  numberOfColumns = config.numberOfColumns or 3
  gridDisplayTimeout = config.gridDisplayTimeout or 0.75
  gridScale = config.gridScale or 0.05
  wrapAround = config.wrapAround or false

  if not yabaiPath then
    -- Try to find yabai binary. We
    local s, status, _, _ = hs.execute("which yabai", true)
    if status then
      -- http://lua-users.org/wiki/StringTrim trim3
      yabaiPath = s:gsub("^%s+", ""):gsub("%s+$", "")
    end
  end

  return self
end

-- Apply default config.
YabaiGridSpaces:applyConfig({
  yabaiPath = "/usr/local/bin/yabai",
})

--------------------------------------------------------------------------------

local yabai = function(args)
  -- https://www.hammerspoon.org/docs/hs.html#execute
  local command = yabaiPath .. " " .. args
  local output, status, type, rc = hs.execute(command)

  if nil == status then
    debug({ command = command, status = status, output = output, type = type, rc = rc })
  end

  return output, status, type, rc
end

local screenFrame = screen.mainScreen():fullFrame()

local getGrid = function()
  local s, status, _, _ = yabai("--message query --spaces")
  if status then
    local spaces = {}
    -- [
    -- …,
    -- {
    --     "id":7,
    --     "uuid":"B7359B82-B974-4BAB-B351-50B45704C199",
    --     "index":5,
    --     "label":"",
    --     "type":"float",
    --     "display":1,
    --     "windows":[1176, 10128, 2285],
    --     "first-window":0,
    --     "last-window":0,
    --     "has-focus":false,
    --     "is-visible":false,
    --     "is-native-fullscreen":false
    -- },
    -- …
    -- ]
    local data = hs.json.decode(s)
    spaces.spaces = {}
    spaces.cols = numberOfColumns
    spaces.rows = math.ceil(#data / numberOfColumns)
    spaces.hasFullScreenSpace = false
    spaces.firstFullScreenIndex = -1

    for index, space in ipairs(data) do
      if space["is-native-fullscreen"] then
        spaces.hasFullScreenSpace = true
        if spaces.firstFullScreenIndex < 0 then
          spaces.firstFullScreenIndex = index - 1
        end
      end
      space.index = space.index - 1
      space.isCurrent = space["has-focus"]
      space.isFullScreen = space["is-native-fullscreen"]
      space.col = space.index % numberOfColumns
      space.row = math.floor(space.index / numberOfColumns)
      table.insert(spaces.spaces, space)
      if space.isCurrent then
        spaces.currentSpace = space
      end
    end
    return spaces
  end
end

-- Get acive window
local getWindow = function()
  local s, status, _, _ = yabai("--message query --windows --window")
  if status then
    -- {
    -- 	"id":1129,
    -- 	"pid":14145,
    -- 	"app":"iTerm2",
    -- 	"title":"yabai --message query --windows --window | pbcopy",
    -- 	"scratchpad":"",
    -- 	"frame":{
    -- 		"x":-0.0000,
    -- 		"y":0.0000,
    -- 		"w":1792.0000,
    -- 		"h":1120.0000
    -- 	},
    -- 	"role":"AXWindow",
    -- 	"subrole":"AXStandardWindow",
    -- 	"root-window":true,
    -- 	"display":1,
    -- 	"space":1,
    -- 	"level":0,
    -- 	"sub-level":0,
    -- 	"layer":"normal",
    -- 	"sub-layer":"normal",
    -- 	"opacity":1.0000,
    -- 	"split-type":"none",
    -- 	"split-child":"none",
    -- 	"stack-index":0,
    -- 	"can-move":true,
    -- 	"can-resize":true,
    -- 	"has-focus":true,
    -- 	"has-shadow":true,
    -- 	"has-parent-zoom":false,
    -- 	"has-fullscreen-zoom":false,
    -- 	"has-ax-reference":true,
    -- 	"is-native-fullscreen":false,
    -- 	"is-visible":true,
    -- 	"is-minimized":false,
    -- 	"is-hidden":false,
    -- 	"is-floating":false,
    -- 	"is-sticky":false,
    -- 	"is-grabbed":false
    -- }
    local data = hs.json.decode(s)

    return data
  end
end

-- https://github.com/asmagill/hammerspoon/wiki/hs.canvas.examples
function showGrid(grid, params)
  if nil == grid then
    return
  end

  params = params or {}

  local currentSpace, arrow = params.currentSpace or grid.currentSpace, params.arrow or {}

  local cellWidth = screenFrame.w * gridScale
  local cellHeight = screenFrame.h * gridScale
  local gap = 10

  local width = cellWidth * grid.cols + (grid.cols + 1) * gap
  local height = cellHeight * grid.rows + (grid.rows + 1) * gap

  if grid.firstFullScreenIndex > 0 then
    height = height + gap
  end

  local alpha = 1

  local a = canvas.new({
    x = (screenFrame.w - width) / 2,
    y = (screenFrame.h - height) / 2,
    w = width,
    h = height,
  })

  a:appendElements({
    type = "rectangle",
    roundedRectRadii = {
      xRadius = gap,
      yRadius = gap,
    },
    fillColor = {
      white = 0.5,
      alpha = alpha,
    },
  })

  if grid.firstFullScreenIndex > 0 then
    local y = gap + (gap + cellHeight) * math.floor(grid.firstFullScreenIndex / grid.cols)
    a:appendElements({
      type = "segments",
      coordinates = {
        { x = gap, y = y },
        { x = width - gap, y = y },
      },

      closed = false,
      strokeColor = {
        white = 0.5,
        alpha = alpha,
      },
    })
  end

  for _, space in ipairs(grid.spaces) do
    if space.index < #grid.spaces then
      local y = gap + (gap + cellHeight) * space.row
      if space.isFullScreen then
        y = y + gap
      end

      local isCurrent = space == currentSpace
      a:appendElements(
        {
          type = "rectangle",
          frame = {
            x = gap + (gap + cellWidth) * space.col,
            y = y,
            w = cellWidth,
            h = cellHeight,
          },
          -- http://lua-users.org/wiki/TernaryOperator
          fillColor = isCurrent and { white = 0.75, alpha = alpha } or { white = 0.5, alpha = alpha },
        }
        -- {
        --   frame = {
        --     x = gap+(gap+ cellWidth)*space.col,
        --     y = y,
        --     w = cellWidth,
        --     h = cellHeight,
        --   },
        --   text = hs.styledtext.new(space.index+1, {
        --                              font = { name = ".AppleSystemUIFont", size = cellHeight/2 },
        --                              paragraphStyle = { alignment = "center" }
        --   }),
        --   type = "text",
        -- }
      )
    end
  end

  if arrow and arrow.from and arrow.to then
    local unit = 10

    a:appendElements({
      type = "segments",
      coordinates = {
        { x = 0.0, y = 0.0 },
        { x = -0.1, y = 0.8 },
        { x = -0.2, y = 0.8 },
        { x = 0.0, y = 1.0 },
        { x = 0.2, y = 0.8 },
        { x = 0.1, y = 0.8 },
        { x = 0.0, y = 0.0 },
      },
      -- https://www.hammerspoon.org/docs/hs.canvas.matrix.html
      transformation = hs.canvas.matrix
        :translate(unit + cellWidth / 2, unit + cellHeight / 2)
        :scale(cellHeight + gap)
        :rotate(0),

      closed = false,
      action = "fill",
      fillColor = {
        red = 0.5,
        -- alpha = alpha,
      },
    })
  end

  a:show()
  a:delete(gridDisplayTimeout)
end

local focusSpace = function(index)
  -- debug([[yabaiPath "--message" "space" "--focus" index]])
  -- https://www.hammerspoon.org/docs/hs.html#execute
  -- local _, status, _, _ = hs.execute [[yabaiPath "--message" "space" "--focus" index]]
  local _, status, _, _ = yabai(" --message space --focus " .. index)

  return status
end

local function getTargetSpace(grid, direction)
  if grid then
    local currentSpace = grid.currentSpace
    if currentSpace then
      local currentRow = currentSpace.row
      local currentColumn = currentSpace.col
      local targetRow = currentRow
      local targetColumn = currentColumn

      if direction == NORTH then
        targetRow = currentRow - 1
      elseif direction == SOUTH then
        targetRow = currentRow + 1
      elseif direction == EAST then
        targetColumn = currentColumn + 1
      elseif direction == WEST then
        targetColumn = currentColumn - 1
      end

      if wrapAround then
        -- @TODO
      else
        if targetColumn < 0 or targetColumn >= grid.cols or targetRow < 0 or targetColumn >= grid.rows then
          return
        end
      end

      local targetSpace = targetColumn + targetRow * grid.cols + 1

      if targetSpace > 0 and targetSpace <= #grid.spaces then
        return targetSpace
      end
    end
  end
end

local function navigate(direction, params)
  params = params or {}

  local grid = getGrid()
  if grid then
    local targetSpace = getTargetSpace(grid, direction)
    if targetSpace then
      if params.moveWindow then
        local window = getWindow()
        if window then
          local s, status, _, _ = yabai("--message window " .. window.id .. " --space " .. targetSpace)
          if status and focusSpace(targetSpace) then
            yabai("--message window " .. window.id .. " --focus")
            showGrid(grid, { currentSpace = grid.spaces[targetSpace] })
          end
        end
      else
        if focusSpace(targetSpace) then
          showGrid(grid, { currentSpace = grid.spaces[targetSpace] })
        end
      end
    end
  end
end

--- YabaiGridSpaces:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for YabaiGridSpaces
---
--- Parameters:
---  * mapping - A table containing hotkey modifier/key details for the following items:
---   * navigateNorth -
---   * navigateEast -
---   * navigateSouth -
---   * navigateWest -
function YabaiGridSpaces:bindHotKeys(mapping)
  local spec = {
    navigateNorth = hs.fnutils.partial(function()
      navigate(NORTH)
    end, self),
    navigateEast = hs.fnutils.partial(function()
      navigate(EAST)
    end, self),
    navigateSouth = hs.fnutils.partial(function()
      navigate(SOUTH)
    end, self),
    navigateWest = hs.fnutils.partial(function()
      navigate(WEST)
    end, self),

    moveWindowNorth = hs.fnutils.partial(function()
      navigate(NORTH, { moveWindow = true })
    end, self),
    moveWindowEast = hs.fnutils.partial(function()
      navigate(EAST, { moveWindow = true })
    end, self),
    moveWindowSouth = hs.fnutils.partial(function()
      navigate(SOUTH, { moveWindow = true })
    end, self),
    moveWindowWest = hs.fnutils.partial(function()
      navigate(WEST, { moveWindow = true })
    end, self),
  }

  hs.spoons.bindHotkeysToSpec(spec, mapping)

  return self
end

--- YabaiGridSpaces:start()
--- Method
--- Start YabaiGridSpaces
---
--- Parameters:
---  * None
function YabaiGridSpaces:start()
  showGrid(getGrid())

  -- TODO Check that yabai can be run
  -- TODO Load configuration from file?
  return self
end

return YabaiGridSpaces
