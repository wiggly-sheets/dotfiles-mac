-- Floating pane toggles: lazygit (alt+g) and yazi (alt+y)
-- Press once: opens a popup in the active window, in the pane's current
-- directory. Press again while open: hides it (process keeps running,
-- fully detached). Press again: the hidden instance is replaced by a fresh
-- one started in the pane's directory at that moment.

local FLOAT_BOUNDS = { 0.07, 0.07, 0.86, 0.86 }

local function find_popup(sid, name)
  -- session.list_blocks is the only view that shows detached blocks.
  local listing = rex.session.list_blocks{ session_id = sid }
  for _, blk in ipairs(listing.blocks or {}) do
    if blk.label == name then
      return { block_id = blk.block_id, detached = blk.placement == "detached" }
    end
  end
  return nil
end

local function active_anchor(view)
  for _, win in ipairs(view.windows or {}) do
    if win.window_id == view.active_window_id then
      for _, layer in ipairs(win.layers or {}) do
        -- Anchor in the tiled layer: moving beside a floating block would
        -- merge the popup into that floating layer, where float_block fails.
        if layer.kind == "tiled" and layer.blocks and layer.blocks[1] then
          return layer.blocks[1].block_id
        end
      end
      -- Layout empty (tiled layer outlives its blocks): fall back to focus.
      return win.focused_block_id
    end
  end
  return nil
end

-- Programs to launch in each popup, as absolute paths. Blocks created from
-- init.lua run with a stripped PATH that misses homebrew, so bare names
-- silently fail and the pane stays a shell.
local APP_PATHS = {
  lazygit = "/opt/homebrew/bin/lazygit",
  yazi   = "/opt/homebrew/bin/yazi",
}

-- Directories to prepend to the block's PATH so the program is found.
local PATH_PREPEND = { "/opt/homebrew/bin" }

local function make_toggle(name)
  return function(ctx, args)
    local sid = ctx.session_id
    local view = rex.session.view{ session_id = sid }
    local found = find_popup(sid, name)
    if found then
      if not found.detached then
        -- Popup is visible: hide it (detach, process stays running).
        local ok, err = pcall(rex.call, "session.detach_block", {
          session_id = sid, block_id = found.block_id,
        })
        if not ok then
          found = nil  -- Block may have closed; create fresh
        else
          return name .. " hidden"
        end
      end
      if found then
        -- Popup is hidden: close it so a fresh one starts in the current dir.
        local ok, err = pcall(rex.call, "block.close", {
          session_id = sid, block_id = found.block_id,
        })
        if not ok then
          found = nil  -- Block already closed; create fresh
        end
      end
    end
    local opts = {
      command = { APP_PATHS[name] },
      path_prepend = PATH_PREPEND,
    }
    -- The popup opens in the directory the key was pressed in. Use block.method
    -- pwd (returns file:// URL) as primary; fall back to process cwd which
    -- the server tracks for shells. Strip file:// prefix; default to home.
    -- Also use the current pane's cwd as the shell's initial working directory.
    if name == "lazygit" or name == "yazi" then
      local cwd = nil
      -- Try block.method pwd first (most accurate for active shell panes).
      local r, err = rex.call("block.method", {
        session_id = sid, block_id = ctx.block_id, method = "pwd",
      })
      if r and r.pwd then
        local p = r.pwd
        p = p:match("^file://[^/]+(/.*)$") or p
        cwd = p
      end
      -- Fallback: query process for foreground cwd (works on any shell block).
      if not cwd then
        local proc_r, proc_err = rex.call("block.method", {
          session_id = sid, block_id = ctx.block_id, method = "process",
        })
        if proc_r and proc_r.foreground then
          local p = proc_r.foreground.cwd
          if p then cwd = p end
        end
      end
      if cwd and cwd ~= "" then opts.cwd = cwd end
    end
    local wid = view.active_window_id
    rex.session.new_layer{
      session_id = sid,
      window_id = wid,
      bounds = FLOAT_BOUNDS,
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        label = name,
        options = opts,
      },
    }
    return name .. " opened"
  end
end

rex.action{ name = "toggle_lazygit", title = "Toggle Lazygit Popup", run = make_toggle("lazygit") }
rex.bind("alt+g", "toggle_lazygit")

rex.action{ name = "toggle_yazi", title = "Toggle Yazi Popup", run = make_toggle("yazi") }
rex.bind("alt+y", "toggle_yazi")

-- Floating television picker: cmd+opt+t
-- Opens tv (television) in a floating pane. Same toggle logic as lazygit/yazi:
-- press once to open, again to hide (detached), again to close+reopen fresh in
-- the current pane's directory.

local function make_tv_toggle()
  return function(ctx, args)
    local sid = ctx.session_id
    local view = rex.session.view{ session_id = sid }
    local found = find_popup(sid, "tv")
    if found then
      if not found.detached then
        local ok, err = pcall(rex.call, "session.detach_block", {
          session_id = sid, block_id = found.block_id,
        })
        if not ok then
          found = nil  -- Block may have closed; create fresh
        else
          return "tv hidden"
        end
      end
      if found then
        local ok, err = pcall(rex.call, "block.close", {
          session_id = sid, block_id = found.block_id,
        })
        if not ok then
          found = nil  -- Block already closed; create fresh
        end
      end
    end
    -- Resolve cwd like lazygit/yazi: block.method pwd -> process.cwd.
    local cwd = nil
    do
      local r, err = rex.call("block.method", {
        session_id = sid, block_id = ctx.block_id, method = "pwd",
      })
      if r and r.pwd then
        local p = r.pwd
        p = p:match("^file://[^/]+(/.*)$") or p
        cwd = p
      end
    end
    if not cwd then
      do
        local proc_r, proc_err = rex.call("block.method", {
          session_id = sid, block_id = ctx.block_id, method = "process",
        })
        if proc_r and proc_r.foreground then
          local p = proc_r.foreground.cwd
          if p then cwd = p end
        end
      end
    end
    local opts = {
      command = { "tv", cwd or "" },
      path_prepend = PATH_PREPEND,
    }
    rex.session.new_layer{
      session_id = sid,
      window_id = view.active_window_id,
      bounds = { 0.07, 0.07, 0.86, 0.86 },
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        label = "tv",
        options = opts,
      },
    }
    return "tv opened"
  end
end

rex.action{ name = "toggle_tv", title = "Toggle Television Popup", run = make_tv_toggle() }
rex.bind("cmd+opt+t", "toggle_tv")

-- Floating superfile finder: cmd+opt+r
-- Same toggle logic as lazygit/yazi, opening in current pane's directory.

local function make_spf_toggle()
  return function(ctx, args)
    local sid = ctx.session_id
    local view = rex.session.view{ session_id = sid }
    local found = find_popup(sid, "spf")
    if found then
      if not found.detached then
        local ok, err = pcall(rex.call, "session.detach_block", {
          session_id = sid, block_id = found.block_id,
        })
        if not ok then
          found = nil
        else
          return "spf hidden"
        end
      end
      if found then
        local ok, err = pcall(rex.call, "block.close", {
          session_id = sid, block_id = found.block_id,
        })
        if not ok then
          found = nil
        end
      end
    end
    local cwd = nil
    do
      local r, err = rex.call("block.method", {
        session_id = sid, block_id = ctx.block_id, method = "pwd",
      })
      if r and r.pwd then
        local p = r.pwd
        p = p:match("^file://[^/]+(/.*)$") or p
        cwd = p
      end
    end
    if not cwd then
      do
        local proc_r, proc_err = rex.call("block.method", {
          session_id = sid, block_id = ctx.block_id, method = "process",
        })
        if proc_r and proc_r.foreground then
          local p = proc_r.foreground.cwd
          if p then cwd = p end
        end
      end
    end
    rex.session.new_layer{
      session_id = sid,
      window_id = view.active_window_id,
      bounds = FLOAT_BOUNDS,
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        label = "spf",
        options = {
          command = { "spf", cwd or "" },
          path_prepend = PATH_PREPEND,
        },
      },
    }
    return "spf opened"
  end
end

rex.action{ name = "toggle_spf", title = "Toggle Superfile Popup", run = make_spf_toggle() }
rex.bind("cmd+opt+r", "toggle_spf")

-- Floating pickers: session switcher (alt+s) and file/directory jump (alt+f).
-- Both run fzf in a one-shot terminal layer; the terminal closes itself when
-- its command exits, so there is nothing to clean up. Blocks created here
-- inherit REX_SESSION/REX_BLOCK for the script's own Rex calls.
--
-- Re-entrancy: if a block with the picker's label already exists anywhere in
-- the session, the action focuses it instead of spawning a second popup.

local function focus_or_create(sid, name, bounds, command)
  local listing = rex.session.list_blocks{ session_id = sid }
  for _, blk in ipairs(listing.blocks or {}) do
    if blk.label == name then
      rex.call("session.focus_block", {
        session_id = sid, block_id = blk.block_id,
      })
      return name .. " focused"
    end
  end
  local view = rex.session.view{ session_id = sid }
  rex.session.new_layer{
    session_id = sid,
    window_id = view.active_window_id,
    bounds = bounds,
    focus = true,
    layout = rex.layout.block{
      flavor = "com.superlogical.terminal.shell",
      label = name,
      options = { command = command },
    },
  }
  return name .. " opened"
end

-- rex-sessionizer asks $REX_SESSION itself (it is set inside the layer) and
-- shows the current session in its list only when it is missing.
rex.action{ name = "session_picker", title = "Open Session Picker", run = function(ctx)
  return focus_or_create(ctx.session_id, "session-picker",
    { 0.1, 0.1, 0.8, 0.8 },
    { "/Users/Zeb/.local/bin/rex-sessionizer" })
end }
rex.bind("alt+s", "session_picker")

-- The jump target is the pane the key was pressed in (ctx.block_id).
rex.action{ name = "fzf_jump", title = "Jump to File or Directory", run = function(ctx)
  return focus_or_create(ctx.session_id, "fzf-jump",
    { 0.15, 0.2, 0.7, 0.6 },
    { "/Users/Zeb/.local/bin/rex-jump", ctx.session_id, ctx.block_id })
end }
rex.bind("alt+f", "fzf_jump")

-- Vim-style pane management: alt+hjkl focus, alt+shift+hjkl swap with the
-- nearest neighbor in that direction, alt+z zoom, alt+r/alt+shift+r rotate
-- the active window's panes one slot cw/ccw, alt+x mirror top<->bottom,
-- alt+shift+u mirror left<->right.

local function active_window(view)
  for _, win in ipairs(view.windows or {}) do
    if win.window_id == view.active_window_id then
      return win
    end
  end
  return nil
end

local function active_tiled(win)
  for _, layer in ipairs(win.layers or {}) do
    -- Layers are back to front and the first is the tiled layer that fills
    -- the window with the split layout.
    if layer.kind == "tiled" then
      return layer
    end
  end
  return nil
end

-- Leaves of the split tree in window order, kept with their split rects.
local function layout_leaves(node, out)
  if node.split then
    layout_leaves(node.split.before, out)
    layout_leaves(node.split.after, out)
  else
    out[#out + 1] = { block_id = node.block_id, rect = node.rect }
  end
  return out
end

-- Leaf blocks after swapping before/after at every split of `dir`; since both
-- traversals visit the same leaves, the result is the new slot order.
local function mirrored_order(node, dir, out)
  if node.split then
    local before, after = node.split.before, node.split.after
    if node.split.direction == dir then
      before, after = after, before
    end
    mirrored_order(before, dir, out)
    mirrored_order(after, dir, out)
  else
    out[#out + 1] = node.block_id
  end
  return out
end

-- Which rect axis a direction runs along, and where the neighbor sits on it.
local SWAP_AXIS = {
  left  = { axis = 1, sign = -1 },
  right = { axis = 1, sign = 1 },
  up    = { axis = 2, sign = -1 },
  down  = { axis = 2, sign = 1 },
}

local function nearest_neighbor(leaves, self_id, dir)
  local a = SWAP_AXIS[dir]
  local me
  for _, lf in ipairs(leaves) do
    if lf.block_id == self_id then me = lf end
  end
  if not me then return nil end
  local best, best_rank
  for _, lf in ipairs(leaves) do
    if lf.block_id ~= me.block_id then
      local my_pos, my_end = me.rect[a.axis], me.rect[a.axis] + me.rect[a.axis + 2]
      local lf_pos, lf_end = lf.rect[a.axis], lf.rect[a.axis] + lf.rect[a.axis + 2]
      -- Only the pane's own edge decides the direction, so gaps never match.
      local gap
      if a.sign == 1 and lf_pos >= my_end - 0.000001 then
        gap = lf_pos - my_end
      elseif a.sign == -1 and lf_end <= my_pos + 0.000001 then
        gap = my_pos - lf_end
      end
      if gap then
        -- The neighbor must also share some of the other axis, or it sits
        -- diagonally and focus_direction would not reach it either.
        local o = 3 - a.axis
        local ov_start = math.max(me.rect[o], lf.rect[o])
        local ov_end = math.min(me.rect[o] + me.rect[o + 2], lf.rect[o] + lf.rect[o + 2])
        local overlap = ov_end - ov_start
        -- vim wincmd order: nearest edge first; equal-edge panes (a
        -- centered row/column) pick the one sharing the most of the
        -- other axis.
        if overlap > 0.02 then
          local rank = { gap, -overlap }
          if not best_rank
            or rank[1] < best_rank[1] - 0.000001
            or (math.abs(rank[1] - best_rank[1]) <= 0.000001 and rank[2] < best_rank[2] - 0.000001) then
            best, best_rank = lf.block_id, rank
          end
        end
      end
    end
  end
  return best
end

rex.action{ name = "vim_swap", title = "Swap Pane With Neighbor", run = function(ctx, args)
  local dir = args and args.direction
  if not SWAP_AXIS[dir] then return "vim_swap: missing direction" end
  local sid = ctx.session_id
  local view = rex.session.view{ session_id = sid }
  local win = active_window(view)
  if not win then return "no active window" end
  local focus = ctx.block_id or win.focused_block_id
  if not focus then return "no focused pane" end
  -- Swaps target the tiled layer only: pressed on a floating popup
  -- (lazygit, yazi, fzf-jump, session-picker) the action does nothing.
  local tiled, focus_tiled = nil, false
  for _, layer in ipairs(win.layers or {}) do
    if layer.kind == "tiled" then tiled = layer end
    for _, blk in ipairs(layer.blocks or {}) do
      if blk.block_id == focus then focus_tiled = layer.kind == "tiled" end
    end
  end
  if not focus_tiled then return "focused pane is floating; vim swaps tile panes only" end
  if not (tiled and tiled.layout) then return "window layout is empty" end
  local neighbor = nearest_neighbor(layout_leaves(tiled.layout, {}), focus, dir)
  if not neighbor then return "no neighbor " .. dir end
  rex.call("session.swap_blocks", {
    session_id = sid, block_id = focus, other_block_id = neighbor,
  })
  return "swapped neighbor " .. dir
end }

rex.action{ name = "vim_layout", title = "Transform Window Layout", run = function(ctx, args)
  local kind = args and args.kind
  local sid = ctx.session_id
  local view = rex.session.view{ session_id = sid }
  local win = active_window(view)
  local tiled = win and active_tiled(win)
  if not (tiled and tiled.layout) then return "no window layout" end
  local leaves = layout_leaves(tiled.layout, {})
  local n = #leaves
  if n < 2 then return "window has " .. n .. " pane(s); nothing to transform" end
  local want
  if kind == "rotate_cw" or kind == "rotate_ccw" then
    local slots = {}
    for i, lf in ipairs(leaves) do slots[i] = lf.block_id end
    want = {}
    -- rotate_cw: the pane in slot i moves to slot i+1, the last wraps to 1.
    for j = 1, n do
      want[j] = slots[(j - 2) % n + 1]
    end
    if kind == "rotate_ccw" then
      want = {}
      for j = 1, n do
        want[j] = slots[j % n + 1]
      end
    end
  elseif kind == "flip_tb" or kind == "flip_lr" then
    -- flip_tb mirrors top<->bottom and therefore reverses vertical splits;
    -- flip_lr mirrors left<->right and reverses horizontal splits.
    want = mirrored_order(tiled.layout, kind == "flip_tb" and "vertical" or "horizontal", {})
  else
    return "vim_layout: missing kind"
  end
  -- Permutations run as plain swap_blocks pairs: each pair is two placed
  -- blocks, so every split keeps its own split_id, direction and ratio,
  -- and the tree shape never changes.
  local cur = {}
  for i, lf in ipairs(leaves) do cur[i] = lf.block_id end
  local swaps = 0
  for k = 1, n do
    if cur[k] ~= want[k] then
      for l = k + 1, n do
        if cur[l] == want[k] then
          rex.call("session.swap_blocks", {
            session_id = sid, block_id = cur[k], other_block_id = cur[l],
          })
          cur[k], cur[l] = cur[l], cur[k]
          swaps = swaps + 1
          break
        end
      end
    end
  end
  -- Focus follows each block into its new slot; put it back so the same
  -- program stays under the cursor, tmux rotate-window style.
  if swaps > 0 and win.focused_block_id then
    rex.call("session.focus_block", {
      session_id = sid, block_id = win.focused_block_id,
    })
  end
  return "vim_layout " .. kind .. ": " .. swaps .. " swap(s)"
end }

-- Focus travel (alt+h/j/k/l): straight to the stock client actions.
rex.bind("alt+h", "pane.focus.left")
rex.bind("alt+j", "pane.focus.down")
rex.bind("alt+k", "pane.focus.up")
rex.bind("alt+l", "pane.focus.right")

-- Swap with nearest neighbor in that direction.
rex.bind("alt+shift+h", "vim_swap", { direction = "left" })
rex.bind("alt+shift+j", "vim_swap", { direction = "down" })
rex.bind("alt+shift+k", "vim_swap", { direction = "up" })
rex.bind("alt+shift+l", "vim_swap", { direction = "right" })

-- Zoom (client action, toggles the focused pane; shift+cmd+enter untouched).
rex.bind("alt+z", "pane.zoom")

-- Layout transforms of the active window's tiled layer.
rex.bind("alt+r", "vim_layout", { kind = "rotate_cw" })
rex.bind("alt+shift+r", "vim_layout", { kind = "rotate_ccw" })
rex.bind("alt+x", "vim_layout", { kind = "flip_tb" })
rex.bind("alt+shift+u", "vim_layout", { kind = "flip_lr" })

-- Equalize all split sizes in the active window (client-only action).
rex.bind("alt+b", "pane.balance")

-- Move the divider the focused pane sits on, in 5% steps of the split
-- (amount omitted: client default is 5; repeats=true so holding re-steps).
rex.bind("alt+ctrl+h", "pane.resize", { direction = "left" })
rex.bind("alt+ctrl+j", "pane.resize", { direction = "down" })
rex.bind("alt+ctrl+k", "pane.resize", { direction = "up" })
rex.bind("alt+ctrl+l", "pane.resize", { direction = "right" })

-- Tab switcher: ctrl+tab cycles tabs in tab order, ctrl+shift+tab in
-- most-recent-first order. Each enters a mode, so Tab/Tab keeps cycling
-- until Enter commits or Escape cancels. Rex has no key-release event, so
-- releasing Ctrl cannot commit; the mode needs a final key.
--
-- The preview swaps the target tab's focused pane into the current tab and
-- zooms it, then swaps it back. Moving or floating that pane instead would
-- close a one-pane tab and lose its place in the tab order. Swapping keeps
-- every split and ratio exact. The cost is a short focus flip between calls.
--
-- Set style to "list" for the floating name list instead of the pane preview.
local TAB_SWITCHER_STYLE = "preview" -- "preview" or "list"

-- shortcut: MRU order sees only commits made by this switcher. Clicking a tab
-- in the tab bar does not update it, so history can lag after mouse switches.
local tab_switcher_mru = {}
local tab_switcher = nil

local function view_window(view, id)
  for _, win in ipairs(view.windows or {}) do
    if win.window_id == id then return win end
  end
  return nil
end

-- The pane a preview uses: the window's focused pane when it is in the tiled
-- layer, otherwise the first tiled pane. Floating panes are skipped because
-- swapping them into another window's tiled slot changes layer kinds.
local function tiled_pane(win)
  if not win then return nil end
  local tiled
  for _, layer in ipairs(win.layers or {}) do
    if layer.kind == "tiled" then tiled = layer end
  end
  if not (tiled and tiled.blocks and tiled.blocks[1]) then return nil end
  for _, blk in ipairs(tiled.blocks) do
    if blk.block_id == win.focused_block_id then return blk.block_id end
  end
  return tiled.blocks[1].block_id
end

-- Home first, then the rest in tab order, or after the MRU history. Only
-- windows with a tiled pane can be previewed.
local function switcher_order(view, home_id, style)
  local ids, start = {}, 1
  for _, win in ipairs(view.windows or {}) do
    ids[#ids + 1] = win.window_id
    if win.window_id == home_id then start = #ids end
  end
  local out, seen = { home_id }, { [home_id] = true }
  local function add(id)
    local win = view_window(view, id)
    if not seen[id] and tiled_pane(win) then
      seen[id] = true
      out[#out + 1] = id
    end
  end
  if style == "mru" then
    for _, id in ipairs(tab_switcher_mru) do
      if view_window(view, id) then add(id) end
    end
  end
  for k = 1, #ids - 1 do
    add(ids[(start - 1 + k) % #ids + 1])
  end
  return out
end

local function mru_touch(id)
  local out = { id }
  for _, other in ipairs(tab_switcher_mru) do
    if other ~= id then out[#out + 1] = other end
  end
  tab_switcher_mru = out
end

-- Put the previewed pane back in its own window. zoom=false uses the window,
-- not the block, so focus does not move before the swap.
local function restore_preview(t)
  if not t.shown_block then return end
  rex.call("session.zoom_block", {
    session_id = t.sid, window_id = t.home_window, zoom = false,
  })
  rex.call("session.swap_blocks", {
    session_id = t.sid,
    block_id = t.shown_block,
    other_block_id = t.home_block,
  })
  t.shown_block, t.shown_window = nil, nil
end

local function show_target(t)
  restore_preview(t)
  local target = t.order[t.idx]
  if target == t.home_window then
    rex.call("session.focus_window", {
      session_id = t.sid, window_id = t.home_window,
    })
    return
  end
  local block = t.panes[target]
  rex.call("session.swap_blocks", {
    session_id = t.sid, block_id = t.home_block, other_block_id = block,
  })
  rex.call("session.zoom_block", {
    session_id = t.sid, block_id = block, zoom = true,
  })
  t.shown_window, t.shown_block = target, block
end

local function list_path(t)
  local dir = (os.getenv("TMPDIR") or "/tmp"):gsub("/$", "")
  return dir .. "/rex-tab-switcher-" .. (t.sid:gsub("[^%w]", "")) .. ".txt"
end

local function write_list(t)
  local lines = {}
  for i, id in ipairs(t.order) do
    local label = t.labels[id] or { "", "" }
    lines[#lines + 1] = string.format("%s %2d  %s  %s",
      i == t.idx and ">" or " ", i, label[1], label[2])
  end
  local f = io.open(t.list_path, "w")
  if f then
    f:write(table.concat(lines, "\n"), "\n")
    f:close()
  end
end

local function close_list(t)
  if t.list_block then
    pcall(rex.call, "block.close", {
      session_id = t.sid, block_id = t.list_block,
    })
  end
  if t.list_path then pcall(os.remove, t.list_path) end
end

local function open_list(t)
  t.list_path = list_path(t)
  write_list(t)
  local existing = find_popup(t.sid, "tab-switcher-list")
  if existing then
    pcall(rex.call, "block.close", {
      session_id = t.sid, block_id = existing.block_id,
    })
  end
  local created = rex.session.new_layer{
    session_id = t.sid,
    window_id = t.home_window,
    bounds = { 0.02, 0.02, 0.36, 0.30 },
    focus = true,
    layout = rex.layout.block{
      flavor = "com.superlogical.terminal.shell",
      label = "tab-switcher-list",
      options = {
        command = { "sh", "-c",
          'while :; do clear; cat "$1"; sleep 0.15; done', "sh", t.list_path },
      },
    },
  }
  t.list_block = created and created.block_ids and created.block_ids[1]
end

local cycle

local function open_switcher(ctx, args, style)
  if tab_switcher then return cycle(1) end
  local sid = ctx.session_id
  local view = rex.session.view{ session_id = sid }
  local home = view and view.active_window_id
  local home_win = view and view_window(view, home)
  local home_block = tiled_pane(home_win)
  if not home_block then return "tab switcher: no tiled pane" end
  local order = switcher_order(view, home, style)
  if #order < 2 then return "tab switcher: one tab" end
  local panes, labels = {}, {}
  for _, id in ipairs(order) do
    local win = view_window(view, id)
    local pane = id == home and home_block or tiled_pane(win)
    panes[id] = pane
    for _, layer in ipairs(win.layers or {}) do
      for _, blk in ipairs(layer.blocks or {}) do
        if blk.block_id == pane then
          labels[id] = { win.label or "", blk.label or "" }
        end
      end
    end
  end
  -- Queue the mode before touching any tab, so a failure leaves the layout
  -- alone. The mode makes unbound keys inert and keeps typing out of the
  -- previewed terminal.
  local ok, err = pcall(rex.client.queue, "client.mode.enter", {
    name = "tab_switcher",
  })
  if not ok then return "tab switcher: " .. tostring(err) end
  tab_switcher = {
    sid = sid, home_window = home, home_block = home_block,
    home_zoom = home_win.zoomed_block_id,
    order = order, idx = 2, panes = panes, labels = labels, style = style,
  }
  if tab_switcher.home_zoom then
    rex.call("session.zoom_block", {
      session_id = sid, window_id = home, zoom = false,
    })
  end
  if style == "list" then open_list(tab_switcher) else show_target(tab_switcher) end
  return "tab switcher: " .. style
end

cycle = function(delta)
  local t = tab_switcher
  if not t then return "tab switcher inactive" end
  t.idx = (t.idx - 1 + delta) % #t.order + 1
  if t.style == "list" then write_list(t) else show_target(t) end
  return "tab " .. t.idx
end

local function finish(commit)
  local t = tab_switcher
  if not t then return "tab switcher inactive" end
  local target = commit and t.order[t.idx] or t.home_window
  if t.style == "list" then close_list(t) else restore_preview(t) end
  if commit and target ~= t.home_window then
    rex.call("session.focus_window", { session_id = t.sid, window_id = target })
    mru_touch(target)
  elseif t.home_zoom then
    -- focus_window would give focus to the wrong pane after the swaps.
    rex.call("session.zoom_block", {
      session_id = t.sid, block_id = t.home_zoom, zoom = true,
    })
  else
    rex.call("session.focus_window", {
      session_id = t.sid, window_id = t.home_window,
    })
  end
  tab_switcher = nil
  pcall(rex.client.queue, "client.mode.exit")
  return commit and ("tab " .. target) or "tab switcher cancelled"
end

rex.mode("tab_switcher", { exclusive = true })

rex.action{ name = "tab_switcher_open", title = "Open Tab Switcher",
  args = { order = "string?" }, run = function(ctx, args)
  return open_switcher(ctx, args, (args and args.order) or "positional")
end }
rex.action{ name = "tab_switcher_next", title = "Tab Switcher Next",
  run = function() return cycle(1) end }
rex.action{ name = "tab_switcher_prev", title = "Tab Switcher Previous",
  run = function() return cycle(-1) end }
rex.action{ name = "tab_switcher_commit", title = "Tab Switcher Commit",
  run = function() return finish(true) end }
rex.action{ name = "tab_switcher_cancel", title = "Tab Switcher Cancel",
  run = function() return finish(false) end }

rex.bind("ctrl+tab", "tab_switcher_open", { order = "positional" })
rex.bind("ctrl+shift+tab", "tab_switcher_open", { order = "mru" })

-- Inside the mode, both the bare key and the still-held ctrl form cycle.
rex.bind("tab_switcher/tab", "tab_switcher_next")
rex.bind("tab_switcher/ctrl+tab", "tab_switcher_next")
rex.bind("tab_switcher/shift+tab", "tab_switcher_prev")
rex.bind("tab_switcher/ctrl+shift+tab", "tab_switcher_prev")
rex.bind("tab_switcher/enter", "tab_switcher_commit")
rex.bind("tab_switcher/escape", "tab_switcher_cancel")
rex.bind("tab_switcher/ctrl+c", "tab_switcher_cancel")
