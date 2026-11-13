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

-- Tab toast: ctrl+tab switches to the next tab across the sessions on this
-- machine, in session order then tab order, wrapping at the end, and shows
-- the tab name, its pane titles in layout order, and the session and machine,
-- in a floating pane for two seconds. ctrl+shift+tab goes the other way. The
-- pane runs one command and exits, so Rex closes it. focus=false keeps typing
-- in the terminal, and the focused pane is restored because creating the pane
-- moves focus.
local TAB_TOAST_SECONDS = 2.0
local TAB_TOAST_BOUNDS = { 0.20, 0.36, 0.60, 0.18 }

local function pane_title(sid, block_id)
  local r = rex.call("block.method", {
    session_id = sid, block_id = block_id, method = "title",
  })
  local t = r and r.title or ""
  t = t:gsub("%s+", " ")
  if t == "" then t = block_id:sub(-6) end
  if #t > 40 then t = t:sub(1, 37) .. "..." end
  return t
end

local function layout_text(sid, node)
  if not node then return "" end
  if node.block_id then return pane_title(sid, node.block_id) end
  local split = node.split
  if not split then return "?" end
  local sep = split.direction == "horizontal" and " | " or " / "
  return layout_text(sid, split.before) .. sep .. layout_text(sid, split.after)
end

local function window_panes(sid, win)
  local layer = (win.layers or {})[1]
  if layer and layer.layout then return layout_text(sid, layer.layout) end
  local parts = {}
  for _, blk in ipairs(layer and layer.blocks or {}) do
    parts[#parts + 1] = pane_title(sid, blk.block_id)
  end
  return table.concat(parts, " | ")
end

-- All tabs on this server, in session order then tab order. Wrapping stays
-- on this host.
local function local_tabs(sid, view)
  local tabs = {}
  pcall(rex.call, "session.attach_all", { event_scope = "session" })
  local ok, r = pcall(rex.call, "session.list")
  for _, s in ipairs(ok and r and r.sessions or {}) do
    local v = s.session_id == sid and view or rex.session.view{ session_id = s.session_id }
    for _, w in ipairs(v and v.windows or {}) do
      tabs[#tabs + 1] = {
        session_id = s.session_id,
        session = s.label or s.session_id,
        win = w,
      }
    end
  end
  return tabs
end

local function close_toast(sid)
  local listing = rex.session.list_blocks{ session_id = sid }
  for _, blk in ipairs(listing and listing.blocks or {}) do
    if blk.label == "tab-toast" then
      pcall(rex.call, "block.close", { session_id = sid, block_id = blk.block_id })
      return
    end
  end
end

rex.action{
  name = "tab_toast",
  title = "Switch Tab With Name Toast",
  repeats = false,
  args = { direction = "string?" },
  run = function(ctx, args)
    local sid = ctx.session_id
    local view = rex.session.view{ session_id = sid }
    if not view then return "no session" end

    local tabs = local_tabs(sid, view)
    if #tabs < 2 then return "one tab" end

    local idx
    for i, t in ipairs(tabs) do
      if t.session_id == sid and t.win.window_id == view.active_window_id then idx = i end
    end
    if not idx then return "no active tab" end

    local step = args.direction == "previous" and -1 or 1
    local target = (idx - 1 + step) % #tabs + 1
    local next_tab = tabs[target]
    local win = next_tab.win
    local target_sid = next_tab.session_id

    close_toast(sid)
    if target_sid ~= sid then close_toast(target_sid) end

    local keep = win.focused_block_id
    if not keep then
      for _, layer in ipairs(win.layers or {}) do
        for _, blk in ipairs(layer.blocks or {}) do
          keep = blk.block_id
          break
        end
        if keep then break end
      end
    end

    local panes = window_panes(target_sid, win)

    local created, cerr = rex.session.new_layer{
      session_id = target_sid,
      window_id = win.window_id,
      bounds = TAB_TOAST_BOUNDS,
      focus = false,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        label = "tab-toast",
        options = {
          shell = "none",
          -- The pane is smaller than the default 24-row terminal, and the
          -- client shows the bottom rows, so size it to the visible area.
          size = { columns = 100, rows = 6 },
          command = {
            "/bin/sh", "-c",
            [=[
clear
printf '\n  \033[1m%s\033[0m\n' "$1"
printf '  %s\n' "$2"
info="$3 · $(hostname -s)"
cols=$(tput cols 2>/dev/null || echo 80)
rows=$(tput lines 2>/dev/null || echo 8)
col=$((cols - ${#info}))
[ "$col" -lt 0 ] && col=0
if tput cup $((rows - 1)) "$col" 2>/dev/null; then
  printf '\033[2m%s\033[0m' "$info"
else
  printf '\n%s\n' "$info"
fi
sleep "$4"
]=],
            "sh", win.label or "tab", panes, next_tab.session, tostring(TAB_TOAST_SECONDS),
          },
        },
      },
    }
    if not created then return "toast failed: " .. tostring(cerr) end

    -- Creating the floating pane moves the window's focus to its first
    -- pane, so put it back before the client switches to that window.
    if keep then
      rex.session.focus_block{ session_id = target_sid, block_id = keep }
    end
    rex.client.queue("session.select", {
      session_id = target_sid,
      window_id = win.window_id,
    })
  end,
}

rex.bind("ctrl+tab", "tab_toast")
rex.bind("ctrl+shift+tab", "tab_toast", { direction = "previous" })
rex.bind("vim/ctrl+tab", "tab_toast")
rex.bind("vim/ctrl+shift+tab", "tab_toast", { direction = "previous" })

-- Vim-style leader mode: ctrl+b, then motions (tmux-style leader). Mirrors the
-- direct alt+ pane bindings above and adds tab and session travel, so one
-- leader covers every motion like a tiling window manager. Escape or ctrl+b
-- again leaves the mode; it is exclusive, so unbound keys do not reach the
-- terminal.
--
-- ctrl+b no longer reaches the terminal: it is the leader, not readline's
-- backward-char.
--
--   h j k l     focus pane left/down/up/right
--   shift+hjkl  swap pane with its neighbor
--   shift+arrows  resize pane
--   [ ]         previous/next tab
--   n p         next/previous session
--   z           zoom pane        b  balance splits
--   f           float pane       s  split right    shift+s  split down
--   arrows      split in that direction
--   r           rotate cw        shift+r  rotate ccw
rex.mode("vim", { exclusive = true })
rex.bind("ctrl+b", "client.mode.enter", { name = "vim" })

rex.bind("vim/h", "pane.focus.left")
rex.bind("vim/j", "pane.focus.down")
rex.bind("vim/k", "pane.focus.up")
rex.bind("vim/l", "pane.focus.right")

rex.bind("vim/shift+h", "vim_swap", { direction = "left" })
rex.bind("vim/shift+j", "vim_swap", { direction = "down" })
rex.bind("vim/shift+k", "vim_swap", { direction = "up" })
rex.bind("vim/shift+l", "vim_swap", { direction = "right" })

-- Resize uses shift+arrows: ctrl+h/j/k/l collide with the control characters
-- for backspace and newline, so those bindings never fire.
rex.bind("vim/shift+left", "pane.resize", { direction = "left" })
rex.bind("vim/shift+down", "pane.resize", { direction = "down" })
rex.bind("vim/shift+up", "pane.resize", { direction = "up" })
rex.bind("vim/shift+right", "pane.resize", { direction = "right" })

rex.bind("vim/[", "client.tab.previous")
rex.bind("vim/]", "client.tab.next")
rex.bind("vim/n", "session.next")
rex.bind("vim/p", "session.previous")

rex.bind("vim/z", "pane.zoom")
rex.bind("vim/ctrl+b", "client.mode.exit")
rex.bind("vim/b", "pane.balance")

-- f float/unfloat the pane, s split side by side, shift+s split stacked.
rex.bind("vim/f", "pane.float")
rex.bind("vim/s", "pane.split", { direction = "right" })
rex.bind("vim/shift+s", "pane.split", { direction = "down" })

-- Arrows split in the arrow's direction; r/shift+r rotate the layout.
rex.bind("vim/left", "pane.split", { direction = "left" })
rex.bind("vim/right", "pane.split", { direction = "right" })
rex.bind("vim/up", "pane.split", { direction = "up" })
rex.bind("vim/down", "pane.split", { direction = "down" })

rex.bind("vim/r", "vim_layout", { kind = "rotate_cw" })
rex.bind("vim/shift+r", "vim_layout", { kind = "rotate_ccw" })

