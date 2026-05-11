# VimMode.spoon - Code Analysis

This document catalogs known flaws, bugs, and architectural issues in the
VimMode.spoon codebase. Each section includes the issue, affected files, and
concrete evidence from the code.

---

## Table of Contents

1. [Timing and Race Conditions](#1-timing-and-race-conditions)
2. [UTF-8 Byte/Character Confusion](#2-utf-8-bytecharacter-confusion)
3. [Global Variable Leaks](#3-global-variable-leaks)
4. [Silent Failures in Fallback Mode](#4-silent-failures-in-fallback-mode)
5. [Accessibility API Fragility](#5-accessibility-api-fragility)
6. [State Machine Edge Cases](#6-state-machine-edge-cases)
7. [Dead and Duplicated Code](#7-dead-and-duplicated-code)
8. [Minor Bugs](#8-minor-bugs)

---

## 1. Timing and Race Conditions

The codebase relies heavily on arbitrary `hs.timer.doAfter` delays and
`hs.eventtap.keyStroke(..., 0)` calls with zero inter-event delay. These
are hopes, not guarantees -- the correct delay depends on the target app's
event processing speed, system load, and accessibility API latency.

### 1a. `hs.timer.doAfter` delay sites

Every `hs.timer.doAfter` call is a fixed-delay workaround for an
asynchronous dependency. None of these delays are adaptive or have any
feedback mechanism to confirm the precondition has been met.

| File | Line | Delay | Purpose | Race condition |
|------|------|-------|---------|----------------|
| `lib/vim.lua` | 286 | 3ms | Enter normal mode after `collapseSelection()` calls `setAttributeValue("AXSelectedTextRange", ...)` | The AX write to collapse the selection is IPC to the target app. If the app takes longer than 3ms to process it (Electron apps regularly do), `enterNormal` fires while the selection is still active, and the block cursor overlay reads stale selection bounds. |
| `lib/vim.lua` | 305 | 5ms | `exitAsync()` -- exit to insert mode, avoiding a modal key-repeat bug where `i` repeats forever | The comment says this "lets us exit the modal key handler and move back to the key sequence tap." If a second key arrives within the 5ms window (fast typist, held key), the modal is still active and may process it before the exit fires. Conversely, if the Hammerspoon run loop is busy, the timer can fire late and the user's next keypress is swallowed by the still-active modal. |
| `lib/vim.lua` | 313 | 5ms | `exitModalAsync()` -- exit all modals after char input (f, t, r) | Same problem as `exitAsync`. The `previousContext` is captured synchronously at line 311 but the modal exit happens asynchronously. If any event arrives during the 5ms window, it is handled by the old modal context, potentially triggering an unintended action. |
| `lib/strategies/accessibility_strategy.lua` | 54 | 100ms | After a linewise operator (e.g. `dd`), wait 100ms then reset cursor to beginning of line | `operator:modifySelection()` fires `hs.eventtap.keyStroke({}, 'delete', 0)` which is itself asynchronous. The 100ms is a guess at how long the app takes to process the deletion and reflow text. In slow apps (large documents, Electron), the deletion may not have committed yet, so `AccessibilityBuffer:new()` at line 56 reads pre-deletion text, and `setSelectionRange` sets the cursor to a now-invalid position. In fast apps, the 100ms is wasted latency. |
| `lib/modal.lua` | 90 | 5ms | After receiving a character for an operator-needing-char (`r`), wait 5ms then fire `enterOperator` + optional motion | The 5ms is needed because `exitModalAsync()` was called at line 76 to leave the current modal, and that itself is on a 5ms timer. Two 5ms timers run independently with no ordering guarantee. If the exit-modal timer fires *after* the enter-operator timer, the operator's modal context gets torn down immediately after being set up. |
| `lib/modal.lua` | 127 | 5ms | After receiving a character for a motion-needing-char (`f`, `t`), wait 5ms then fire `enterMotion` | Same dual-timer race as line 90. Additionally, `vim:enterModal(previousContext)` is called synchronously at line 126 before the timer. If the `exitModalAsync` timer from line 112 fires after this synchronous `enterModal`, it exits the context that was just entered. |
| `lib/key_sequence.lua` | 67 | configurable (default 140ms) | Timeout for multi-key escape sequence (e.g. "jk") | This is the only well-designed timer -- it is a genuine timeout, not a race-avoidance hack. However, `startTimer` replaces `self.timer` without stopping the old one first (the cancel happens earlier in the flow at line 101, but if `startTimer` were ever called twice without an intervening cancel, the old timer would leak). |

### 1b. Zero-delay keystroke sequences

`hs.eventtap.keyStroke(mods, key, delay)` with `delay = 0` posts a
keyDown and keyUp event with no inter-event pause. When multiple such
calls execute in sequence, the events are posted to the app's event queue
back-to-back. The app must fully process each keystroke before the next
arrives; if it does not, events are reordered, coalesced, or dropped.
Electron and web-based apps are particularly vulnerable because their
event loop processes CGEvents asynchronously.

#### Single zero-delay keystrokes (lower risk but not safe)

These fire one `keyStroke` in isolation. They still race against the
*preceding* AX write or *following* timer, but at least there is no
keystroke-to-keystroke ordering dependency.

| File | Line | Keys | Context |
|------|------|------|---------|
| `lib/modal.lua` | 273 | `Right` (delay 0) | `a` in normal mode -- move cursor right, then `exitAsync()`. The cursor-right may not have been processed before the 5ms exit timer fires and the sequence tap re-enables. |
| `lib/modal.lua` | 284 | `Cmd+F` (delay 0) | `/` search -- opens find dialog, then `exitAsync()`. |
| `lib/modal.lua` | 288 | `Cmd+V` (delay 0) | `p` paste. |
| `lib/modal.lua` | 297 | `Cmd+Z` (delay 0) | `u` undo. |
| `lib/modal.lua` | 301 | `Cmd+Shift+Z` (delay 0) | `Ctrl+R` redo. |
| `lib/operators/delete.lua` | 22 | `Delete` (delay 0) | Delete operator fires backspace after AX selection. Races against the preceding `setAttributeValue("AXSelectedTextRange")` -- if the selection has not been applied yet, backspace deletes one character instead of the selected range. |
| `lib/strategies/keyboard_strategy.lua` | 44 | per-motion key (delay 0) | Keyboard fallback fires each movement key. When a motion returns multiple movements, they are fired in a loop -- see "multi-keystroke sequences" below. |
| `lib/strategies/keyboard_strategy.lua` | 56 | per-operator key (delay 0) | After movements, operator keys are fired in a loop. |

#### Multi-keystroke sequences (high risk)

These fire 2+ `keyStroke` calls in immediate succession. Each depends on
the previous keystroke being fully processed.

| File | Lines | Keys in sequence | Context | Failure mode |
|------|-------|------------------|---------|--------------|
| `lib/modal.lua` | 291-292 | `Cmd+Right`, `Return` | `o` -- open line below. If `Cmd+Right` (end of line) has not been processed, `Return` inserts a newline at the wrong position, splitting the current line mid-text. |
| `lib/modal.lua` | 306-308 | `Cmd+Left`, `Return`, `Up` | `O` -- open line above. Three keystrokes in sequence. If `Cmd+Left` is slow, `Return` splits at the wrong column. If `Return` is slow, `Up` moves from the wrong line. In Electron apps, all three can arrive before any is processed, and the app may handle them in a different order or drop some entirely. |
| `lib/operators/replace.lua` | 15-19 | `Delete` (delay 50), `keyStrokes(replacement)`, then N x `Left` (delay 0) | `r` replace operator. The `Delete` at line 15 uses a 50ms delay (the only non-zero keystroke delay in the codebase), acknowledging that the selection-delete needs time. But `keyStrokes(replacement)` at line 16 fires immediately after with no delay, racing against the delete. Then `N` left-arrow keystrokes fire in a tight loop with zero delay. If the replacement text has not been inserted yet, the left-arrows move through old text. |
| `lib/strategies/keyboard_strategy.lua` | 35-45 | loop over `movements` | Keyboard strategy fires all movement keys from `motion.getMovements()` in a `for` loop with zero delay each. A multi-step motion produces back-to-back keystrokes with no inter-event pause. |
| `lib/strategies/keyboard_strategy.lua` | 55-57 | loop over operator keys | Same pattern -- operator keys fired in a tight loop after the movement loop. The movement and operator keystrokes are also not separated by any delay. |

#### Keystroke-then-timer interactions

Several bindings fire a keystroke and then schedule an async mode
transition. The keystroke and the timer are completely independent:

| Binding | Keystroke(s) | Timer | Race |
|---------|-------------|-------|------|
| `a` (normal) | `Right` (delay 0) at modal.lua:273 | `exitAsync()` 5ms at modal.lua:274 | If Right is slow (Electron), exit fires before cursor moves, and the next typed character lands at the old position. |
| `/` (normal) | `Cmd+F` (delay 0) at modal.lua:284 | `exitAsync()` 5ms at modal.lua:285 | If Cmd+F opens the find dialog slowly, the insert-mode re-enable happens before the dialog has focus. |
| `o` (normal) | `Cmd+Right` + `Return` at modal.lua:291-292 | `exitAsync()` 5ms at modal.lua:293 | The 5ms timer can fire between the two keystrokes if the run loop gets a chance to process timers between the synchronous `keyStroke` calls. |
| `O` (normal) | `Cmd+Left` + `Return` + `Up` at modal.lua:306-308 | `exitAsync()` 5ms at modal.lua:309 | Three keystrokes with a timer -- most fragile combination in the codebase. |

### 1c. `hs.timer.new` polling

| File | Line | Interval | Purpose | Problem |
|------|------|----------|---------|---------|
| `lib/block_cursor.lua` | 29 | 16.7ms (60 fps) | Redraws the block cursor overlay by polling AX API for character bounds | Every frame calls `AccessibilityBuffer:new(self.vim)`, which does an IPC round-trip to `ax.systemWideElement():attributeValue("AXFocusedUIElement")`, then `parameterizedAttributeValue("AXBoundsForRange", ...)`. At 60fps this is ~60 IPC calls/sec minimum. The polling has no synchronization with the write operations in `AccessibilityStrategy:fire()` -- the cursor overlay can read bounds for a selection range that is mid-update, causing the overlay to flicker or jump to a stale position for one frame. |

### 1d. Unsynchronized AX write-then-read sequences

The macOS Accessibility API is IPC-based: `setAttributeValue` sends a
message to the target application, which processes it asynchronously.
A subsequent `attributeValue` read may return the *old* value if the
app has not yet processed the write. The codebase has several
write-then-read sequences with no synchronization.

**`AccessibilityStrategy:fire()` -- operator path (accessibility_strategy.lua:42-63)**

```
line 51:  self:setSelection(start, length)          -- AX WRITE
line 52:  operator:modifySelection(buffer, ...)      -- may fire keyStroke (AX WRITE via event)
line 54:  hs.timer.doAfter(100 / 1000, function()
line 56:    local newBuffer = AccessibilityBuffer     -- AX READ (new buffer)
line 57:      :new()
line 58:      :setSelectionRange(start, 0)            -- AX WRITE
```

The `setSelection` at line 51 writes `AXSelectedTextRange` to select the
text range. `modifySelection` at line 52 (for Delete/Change) immediately
fires `hs.eventtap.keyStroke({}, 'delete', 0)`, which depends on the
selection being visible to the app. If the app has not yet applied the
selection, the delete key deletes one character instead of the entire
range. Then the 100ms timer creates a new buffer (AX READ of the current
element and text value) and writes a new selection range, but the delete
keystroke may not have been processed yet.

**`AccessibilityStrategy:fire()` -- motion path (accessibility_strategy.lua:64-101)**

```
line 65:  local currentRange = buffer:getSelectionRange()  -- cached AX READ
line 100: AccessibilityBuffer:new(self.vim):setSelectionRange(location, length)  -- AX WRITE
```

The motion path reads the current selection (cached from buffer creation),
computes a new position, then writes a new selection. This is safe in
isolation because the read happens before any write. But the block cursor
timer at 60fps may call `getSelectionRange` or `AXBoundsForRange` in
between via `_renderFrame`, creating a read-write-read interleaving with
the potential for stale bounds during the transition.

**`VimMode:collapseSelection()` (vim.lua:332-346) followed by `enter()` timer**

```
line 337:  strategy:setSelection(self.visualCaretPosition, 0)  -- AX WRITE
-- or --
line 343:  strategy:setSelection(selection.location, 0)        -- AX WRITE
line 286:  hs.timer.doAfter(3 / 1000, function()
line 287:    self.state:enterNormal()                           -- reads AX state
line 288:  end)
```

`collapseSelection` writes a zero-length selection to the AX element.
3ms later, `enterNormal` fires, which calls `enableBlockCursor`, which
starts the 60fps redraw timer. The redraw timer immediately reads
`AXSelectedTextRange` and `AXBoundsForRange`. If the collapse write has
not been applied by the target app within 3ms, the block cursor draws at
the old (pre-collapse) selection bounds.

**`AccessibilityBuffer` chained writes (accessibility_buffer.lua:59-61)**

`resetToBeginningOfLineForIndex` calls `getCurrentLineRange()` (AX READ
of `AXRangeForLine`) then `setSelectionRange` (AX WRITE). This is called
inside the 100ms timer at `accessibility_strategy.lua:54`. The read
depends on the preceding delete having been processed, and the write
depends on the read returning valid data. Both assumptions can fail if
the 100ms was not long enough.

**`lib/utils/debug.lua` lines 89-90 and 103-106 -- test harness**

The debug test suite calls `setAttributeValue('AXValue', ...)` and
immediately reads back `attributeValue('AXValue')`. This appears to
work only because the test harness runs against simple text fields in
native apps where AX round-trip time is sub-millisecond. The same
pattern would fail in Electron apps where AX writes are queued.

---

## 2. UTF-8 Byte/Character Confusion

Several places use Lua's `#` operator (byte length) where `utf8.len()`
(character count) is needed. Since the codebase correctly uses `luautf8`
for string operations like `utf8.sub`, mixing byte-based indices with
character-based operations produces wrong results for any multibyte text.

### Known sites

#### `stringUtils.lastChar` -- byte length used as character index

`lib/utils/string_utils.lua` line 104:

```lua
function stringUtils.lastChar(text)
  return utf8.sub(text, #text, #text)
end
```

`#text` returns the byte length, but `utf8.sub` expects character indices. For
the string `"caf\195\169"` (the word "cafe" with an accented e), `#text` is 5
(bytes) but `utf8.len(text)` is 4 (characters). The call becomes
`utf8.sub(text, 5, 5)` which is past the end of a 4-character string, returning
an empty string instead of `"\195\169"`.

This function is called by `LineEnd.getRange()` in `lib/motions/line_end.lua`
line 11 to detect trailing newlines. If the last character on a line is a
multibyte character, `lastChar` returns `""` instead of the actual character.
The newline check `lastChar(line) == "\n"` still works by accident (a line
ending in a multibyte character would not match `"\n"`), but the function is
semantically wrong and would break any future caller that depends on it
returning the actual last character.

Fix: `return utf8.sub(text, utf8.len(text), utf8.len(text))`

#### `stringUtils.toChars` -- byte length used as character count

`lib/utils/string_utils.lua` lines 34-44:

```lua
function stringUtils.toChars(str)
  local chars = {}
  local current = 1

  while current <= #str do
    table.insert(chars, utf8.sub(str, current, current))
    current = current + 1
  end

  return chars
end
```

The loop bound `#str` is the byte length, but `current` is used as a character
index in `utf8.sub`. For the string `"cafe\204\129"` (the word "cafe" followed
by a combining accent, 6 bytes, 5 characters), `#str` is 6 so the loop runs 6
iterations. On iterations 1-5 it correctly extracts characters 1-5, but
iteration 6 calls `utf8.sub(str, 6, 6)` on a 5-character string, yielding an
empty string. The result is `{"c", "a", "f", "e", "\204\129", ""}` -- a
spurious empty entry at the end.

For a string like `"\195\169\195\168"` ("e-acute, e-grave", 4 bytes, 2
characters), `#str` is 4, so the loop runs 4 times: iterations 1-2 return
the two characters, but iterations 3-4 call `utf8.sub` with out-of-range
indices and produce empty strings. The result is `{"\195\169", "\195\168",
"", ""}` instead of `{"\195\169", "\195\168"}`.

This function is called by `KeySequence:new()` in `lib/key_sequence.lua`
line 10 to split the escape sequence string (e.g. `"jk"`) into individual
characters. Since escape sequences are typically ASCII, this bug does not
trigger in practice, but the function is broken for any multibyte input.

Fix: change `#str` to `utf8.len(str)`

#### `Buffer:getRangeForLineNumber` -- byte length used as character count

`lib/buffer.lua` lines 188-200:

```lua
function Buffer:getRangeForLineNumber(lineNumber)
  local lines = self:getLines()
  local start = 0

  for i, line in ipairs(lines) do
    if i == lineNumber then break end
    start = start + utf8.len(line)
  end

  local length = #lines[lineNumber]

  return Selection:new(start, length)
end
```

The `start` calculation on line 194 correctly uses `utf8.len(line)` (character
count). But line 197 uses `#lines[lineNumber]` which returns the byte length
of the line. The returned `Selection` has a character-based `location` and a
byte-based `length`, mixing two incompatible units in a single object.

For a line containing `"caf\195\169\n"` ("cafe" with accent + newline, 6
bytes, 5 characters), `#lines[lineNumber]` returns 6 but the character count
is 5. This inflated length propagates to:

- `Buffer:getPositionForLineAndColumn` (line 168): `maxColumn` is set to the
  byte length, so column clamping allows positions past the end of the line.
- `Buffer:getCurrentColumn` (line 176): indirectly via `getCurrentLineRange`,
  the line range has wrong length, which could cause column calculations to
  be off if any code uses `lineRange.length`.
- `LineEnd.getRange()` in `lib/motions/line_end.lua` line 9: calls
  `lineRange:positionEnd()` which computes `start + length`. Since `length`
  is in bytes but `start` is in characters, the resulting `finish` position
  overshoots. For the `"caf\195\169\n"` example, it would return `finish =
  start + 6` instead of `start + 5`, placing the cursor one position past
  the actual end of the line. The `$` motion would move the cursor to the
  wrong position.

Fix: change `#lines[lineNumber]` to `utf8.len(lines[lineNumber])`

### Safe uses of `#` (not bugs)

The following uses of `#` in the codebase are on tables or ASCII-only strings
and are not UTF-8 bugs:

| File | Line | Expression | Why safe |
|------|------|-----------|----------|
| `lib/buffer.lua` | 83 | `#lines` | Table length (number of lines), not string length |
| `lib/buffer.lua` | 135 | `#self:getLines()` | Table length |
| `lib/accessibility_buffer.lua` | 166 | `#patterns` | Table length |
| `lib/contextual_modal.lua` | 81 | `#keyChars` | String is `"abcdefghijklmnopqrstuvwxyz1234567890"`, ASCII-only |
| `lib/key_sequence.lua` | 108 | `#self.keys` | Table length (result of `toChars`) |
| `lib/utils/ax.lua` | 26 | `#children` | Table length (AX element children array) |
| `lib/utils/version.lua` | 9 | `#compare`, `#current` | Table lengths (arrays from split) |
| `lib/utils/table.lua` | 6 | `#table1`, `#table2` | Table lengths |
| `lib/utils/inspect.lua` | 147, 155, 196, 197 | various | Table lengths (internal inspector arrays) |
| `lib/utils/log.lua` | 49 | `#t + 1` | Table length |

### No `string.len` or `:len()` usage found

A search for `string.len` and `:len()` across all `.lua` files in `lib/` and
`spec/` found zero matches. The codebase consistently uses either `#` or
`utf8.len()` -- the problem is using `#` where `utf8.len()` is needed.

### Summary of downstream impact

The three bugs above compound. `Buffer:getRangeForLineNumber` is the most
impactful because it feeds into multiple motion calculations. Any line
containing a multibyte character (accented letters, CJK characters, emoji)
will have an incorrect range, causing the `$` motion to overshoot, `0`/`^`
to miscalculate the column, and line-based operators (`dd`, `cc`, `yy`) to
select the wrong span of text.

The `lastChar` bug is currently masked by its only caller (a newline check),
but would cause incorrect behavior for any future use. The `toChars` bug is
currently masked by its only caller using ASCII input.

---

## 3. Global Variable Leaks

Multiple assignments missing `local`, polluting the global namespace.
This can cause subtle cross-module interference where one function's
local state silently overwrites another's.

### Intentional globals

These are deliberately global and used across modules:

| File | Line | Code | Purpose |
|------|------|------|---------|
| `init.lua` | 1 | `inspect = hs.inspect.inspect` | Exposes inspector globally |
| `init.lua` | 8 | `vimModeScriptPath = scriptPath()` | Global path for all `dofile` calls |
| `lib/vim.lua` | 15 | `vimLogger = hs.logger.new('vim', 'debug')` | Global logger used across modules |
| `lib/axuielement.lua` | 4 | `vimModeAxLibrary = nil` | Cached AX library (comment says intentional) |

### Unintentional globals

| File | Line | Code | Overwrites |
|------|------|------|------------|
| `lib/accessibility_buffer.lua` | 158 | `config = self.vim.config` | Global `config` set on every call to `onFallbackOnlyUrl()`. Leaks the vim config object into the global namespace, where any other code reading a global `config` will get a stale or unexpected value. |
| `lib/accessibility_buffer.lua` | 181 | `url = browserUtils.frontmostCurrentUrl()` | Global `url` set on every call to `onFallbackOnlyUrl()` when a browser is frontmost. Overwrites any prior global `url` and persists the last-checked URL in global scope. |
| `lib/utils/benchmark.lua` | 1 | `function vimBenchmark(name, fn)` | The entire function is declared as a global. This is semi-intentional (it is called elsewhere via the global name), but it means loading the benchmark utility permanently installs a global function. |
| `lib/utils/benchmark.lua` | 3 | `result = fn()` | Global `result` overwritten on every benchmark call. The return value of whatever function is being benchmarked leaks into the global namespace. |
| `lib/utils/benchmark.lua` | 6 | `time = (finish - start) / 100000` | Global `time` overwritten on every benchmark call. This shadows any global `time` and persists the last measured duration. |
| `lib/utils/browser.lua` | 17 | `result, url = hs.osascript.applescript(...)` | Inside `frontmostCurrentUrl()`, the Chrome branch assigns to global `result` and global `url` because both lack `local`. Every call when Chrome is frontmost overwrites these globals. |
| `lib/utils/browser.lua` | 25 | `result, url = hs.osascript.applescript(...)` | Same leak in the Safari branch of `frontmostCurrentUrl()`. Overwrites global `result` and `url` when Safari is frontmost. |
| `lib/modal.lua` | 62 | `visibleRange = buffer:visibleLineRange()` | Inside the `pageDirection` closure, `visibleRange` is assigned without `local`. Every Ctrl+D / Ctrl+U page scroll overwrites a global `visibleRange`. |

### Impact analysis

The `config` leak in `accessibility_buffer.lua` line 158 is the most
dangerous: it fires on every keystroke in normal mode (since
`isValid()` calls `onFallbackOnlyUrl()`) and overwrites a very
common variable name. Any Hammerspoon code or other Spoon that reads
a global `config` will silently get VimMode's config object.

The `result` and `url` leaks in `browser.lua` are similarly risky
because `result` is an extremely common variable name and gets
overwritten to a boolean on each call.

The `benchmark.lua` leaks are lower risk since the benchmark utility
is typically only used during development, but `result` and `time`
are common names that could mask bugs elsewhere.

The `visibleRange` leak in `modal.lua` is moderate risk -- it fires
on every page-scroll command and could interfere with any code that
uses a global of the same name.

---

## 4. Silent Failures in Fallback Mode

Many motions return `nil` from `getMovements()`, meaning they only work
with the accessibility strategy. In keyboard fallback mode, these
operations silently eat the user's keystrokes with no feedback.

### How the fallback works

In `lib/vim.lua` (around line 358), the strategy selection tries
`AccessibilityStrategy` first, then falls back to `KeyboardStrategy`.
In `lib/strategies/keyboard_strategy.lua`:

- **`fireMovement()` (line 32)**: calls `motion.getMovements()`. If the
  result is `nil`, it returns `false` and the operator never fires. The
  user's keypress is consumed with zero feedback -- no error, no alert,
  no mode change.
- **`fireOperator()` (line 55)**: calls `operator:getKeys()` and passes
  the result directly to `pairs()`. If `getKeys()` returns `nil`, Lua
  throws a runtime error: `bad argument #1 to 'pairs' (table expected,
  got nil)`. This is a crash, not a silent failure.

### Motion compatibility matrix

Each motion's `getMovements()` return value determines whether it works
in keyboard fallback mode.

| Motion file | Vim key(s) | `getMovements()` | Fallback behavior |
|---|---|---|---|
| `left.lua` | `h`, Left | `[{}, 'left']` | Works: simulates Left arrow |
| `right.lua` | `l`, Right | `[{}, 'right']` | Works: simulates Right arrow |
| `up.lua` | `k`, Up | `[{}, 'up']` | Works: simulates Up arrow |
| `down.lua` | `j`, Down | `[{}, 'down']` | Works: simulates Down arrow |
| `word.lua` | `w` | `[{alt}, 'right']` | Works: simulates Alt+Right |
| `big_word.lua` | `W` | `[{alt}, 'right']` | Works: simulates Alt+Right |
| `end_of_word.lua` | `e` | `[{alt}, 'right']` | Works: simulates Alt+Right |
| `back_big_word.lua` | `B` | `[{alt}, 'left']` | Works: simulates Alt+Left |
| `back_word.lua` | `b` | `[{' alt'}, 'left']` | **Broken**: modifier has leading space (see bug below) |
| `line_beginning.lua` | `0` | `[{ctrl}, 'a']` | Works: simulates Ctrl+A |
| `line_end.lua` | `$` | `[{ctrl}, 'e']` | Works: simulates Ctrl+E |
| `entire_line.lua` | `dd`/`cc`/`yy` | `[{cmd}, 'left'], [{cmd}, 'right']` | Works: Cmd+Left then Cmd+Right with selection |
| `first_line.lua` | `gg` | `[{cmd}, 'up'], [{ctrl}, 'a']` | Works: Cmd+Up then Ctrl+A with selection |
| `last_line.lua` | `G` | `[{cmd}, 'down'], [{ctrl}, 'e'], [{ctrl}, 'a']` | Works: Cmd+Down, Ctrl+E, Ctrl+A with selection |
| `current_selection.lua` | (visual operators) | `{}` (empty table) | Works: no movement needed, just fires operator |
| `forward_search.lua` | `f{char}` | `nil` | **Silent no-op**: keystroke eaten |
| `backward_search.lua` | `F{char}` | `nil` | **Silent no-op**: keystroke eaten |
| `till_before_search.lua` | `t{char}` | `nil` | **Silent no-op**: keystroke eaten |
| `till_after_search.lua` | `T{char}` | `nil` | **Silent no-op**: keystroke eaten |
| `between_chars.lua` | `i(`, `i{`, `i[`, `i<`, `i'`, `i"`, `` i` `` | `nil` | **Silent no-op**: keystroke eaten |
| `in_word.lua` | `iw` | `nil` | **Silent no-op**: keystroke eaten |
| `first_non_blank.lua` | `^` (used by `I`) | `nil` | **Silent no-op**: keystroke eaten |
| `noop.lua` | (internal, Ctrl+D/U fallback) | `nil` | **Silent no-op**: intentional |

### Operator compatibility matrix

| Operator file | Vim key(s) | `getKeys()` | Fallback behavior |
|---|---|---|---|
| `delete.lua` | `d`, `x` | `[{}, 'delete']` | Works: simulates Delete key |
| `change.lua` | `c`, `s` | inherits Delete: `[{}, 'delete']` | Works: simulates Delete, then enters insert mode |
| `yank.lua` | `y` | `[{cmd}, 'c']` | Works: simulates Cmd+C |
| `replace.lua` | `r{char}` | `nil` | **Crash**: `pairs(nil)` throws runtime Lua error |

### Semantic mismatches in fallback

Even when `getMovements()` returns a value, the keyboard shortcut may
not match the vim motion's semantics:

- **`w`, `e`, and `W` all map to Alt+Right.** In vim, `w` moves to the
  start of the next word, `e` moves to the end of the current word, and
  `W` moves to the start of the next WORD. In fallback mode all three
  are identical, producing incorrect cursor positions for `e` and
  potentially for `w` versus `W`.

- **`B` and `b` both map to Alt+Left.** macOS Alt+Left jumps by
  "word" (platform-defined boundaries), which does not match vim's
  distinction between `word` and `WORD` classes. Additionally, `b` has
  the leading-space modifier bug described below.

- **`first_line` (`gg`) uses Ctrl+A for "beginning of line"**, which is
  an Emacs/macOS binding. Apps that do not support Ctrl+A (e.g. some
  Electron apps) will not move to the beginning of the line after
  jumping to the top.

- **`last_line` (`G`) fires three keystrokes in sequence** (Cmd+Down,
  Ctrl+E, Ctrl+A) at zero delay. The Ctrl+E and Ctrl+A pair is
  intended to select from end-of-line back to beginning-of-line, but
  this depends on all three being processed in order with no drops.

### Bug: leading space in `back_word.lua` modifier

`lib/motions/back_word.lua` line 100 specifies `modifiers = { ' alt' }`
with a leading space character. The `hs.eventtap.keyStroke` API likely
does not recognize `' alt'` as a valid modifier, so pressing `b` in
keyboard fallback mode simulates a bare Left arrow press (no Alt) or
does nothing, depending on how Hammerspoon handles unrecognized
modifier strings. Compare with `back_big_word.lua` which correctly uses
`{ 'alt' }`.

### Commands gated by `advancedModeOnly`

Only one normal-mode binding is explicitly gated:

- **`I` (Shift+i)**: wrapped in `advancedModeOnly()` in `lib/modal.lua`
  line 323. This correctly prevents it from running in fallback mode
  since it depends on `FirstNonBlank`, which returns `nil` from
  `getMovements()`. However, the guard produces no user feedback either
  -- the keypress is silently dropped.

All other accessibility-only motions (`f`, `F`, `t`, `T`, `iw`,
`i(`, etc.) are **not** gated. They accept the keypress, wait for a
character input if needed, then silently discard everything when
`getMovements()` returns `nil`.

### Summary of broken commands in fallback mode

| Vim command | Failure mode | User experience |
|---|---|---|
| `f{char}` | Silent no-op | Types char, nothing happens, stays in normal mode |
| `F{char}` | Silent no-op | Types char, nothing happens, stays in normal mode |
| `t{char}` | Silent no-op | Types char, nothing happens, stays in normal mode |
| `T{char}` | Silent no-op | Types char, nothing happens, stays in normal mode |
| `iw` | Silent no-op | Nothing happens, stays in normal mode |
| `i(`, `i{`, `i[`, `i<`, `i'`, `i"`, `` i` `` | Silent no-op | Nothing happens, stays in normal mode |
| `b` | Wrong movement | Moves left incorrectly due to `' alt'` modifier bug |
| `I` | Silent no-op | Gated by `advancedModeOnly`, no feedback |
| `r{char}` (standalone) | Lua crash | `pairs(nil)` error in `fireOperator()` |
| `Ctrl+d` / `Ctrl+u` | Silent partial failure | Fires Down/Up repeatedly, but if buffer is invalid fires `Noop` which returns `nil` -- silent no-op |
| `df{char}`, `cf{char}`, `yf{char}`, etc. | Silent no-op | Motion returns `nil`, operator never fires |
| `diw`, `ciw`, `yiw` | Silent no-op | Motion returns `nil`, operator never fires |
| `di(`, `ci(`, `yi(`, etc. | Silent no-op | Motion returns `nil`, operator never fires |

---

## 5. Accessibility API Fragility

### Blind AX patching

`lib/utils/ax.lua` lines 32-60 and `lib/hot_patcher.lua` lines 3-12
unconditionally set both `AXEnhancedUserInterface` and
`AXManualAccessibility` on **every** application that receives focus, via
an `hs.application.watcher` that fires on every `activated` event. The
two patch functions (`patchChromiumWithAccessibilityFlag` and
`patchElectronAppsWithAccessibilityFlag`) are called sequentially on the
same `axApp` object with no conditional check for the application type:

```lua
-- lib/utils/ax.lua lines 56-59
if axApp then
  patchChromiumWithAccessibilityFlag(axApp)       -- AXEnhancedUserInterface = true
  patchElectronAppsWithAccessibilityFlag(axApp)   -- AXManualAccessibility = true
end
```

The `alreadyPatchedApps` table (line 43) caches by `name .. pid`, so
each process is patched only once per Hammerspoon session. However, this
cache is a module-level local that is **never pruned** -- terminated
processes leave stale entries forever (see also the focus watcher leak
below).

There is also a **duplicate** patching path:
`AccessibilityBuffer:enableLiveApplicationPatches()` (line 271 of
`accessibility_buffer.lua`) sets the same two flags. This method is
defined but never called from any code path, making it dead code that
could confuse future maintainers into adding a second patching site.

Known issues with these flags on specific apps:

| Flag | Intended target | Effect on other apps |
|------|----------------|---------------------|
| `AXEnhancedUserInterface` | Chromium-based browsers | Forces the app to expose its full AX tree. In apps like Preview, TextEdit, and native macOS apps this is harmless but unnecessary. In performance-sensitive apps (Final Cut Pro, Logic Pro, large Xcode projects) it can cause measurable UI lag because the system begins serializing AX tree updates that the app would normally skip. |
| `AXManualAccessibility` | Electron apps | Tells the app that an assistive technology is actively reading its tree. In apps that respond to this flag (e.g. Firefox, which has its own accessibility activation logic) it can trigger an accessibility mode the user did not request, potentially changing rendering behavior or enabling screen-reader announcements. |

The hardcoded `bannedApps` list in `accessibility_buffer.lua` lines 13-30
names three apps with broken AX support:

- **Code** (VS Code) -- recommended to always use fallback mode
- **Notion** -- cells do not work with advanced mode
- **Slack** -- `AXSelectedTextRange` always returns `{ loc = 0, len = 0 }`

Users can add apps to the fallback list via `vim:useFallbackMode(name)`
or `self.vim.config.fallbackOnlyApps`, but there is no runtime detection
of whether an app's AX implementation is actually functional.

### isRichTextField heuristic

`lib/utils/ax.lua` lines 13-27 define `isRichTextField` as: a text field
is "rich" if `element:attributeValue("AXChildren")` returns a non-empty
table. This check is used in `AccessibilityBuffer:isValid()` (line 151)
to force fallback mode for any field deemed rich:

```lua
-- lib/utils/ax.lua lines 13-27
axUtils.isRichTextField = function(element)
  if not element then return false end
  local children = element:attributeValue("AXChildren")
  if not children then return false end
  return #children > 0
end
```

The heuristic assumes that plain text fields never have child elements.
This is incorrect in several common cases:

- **Scroll bars**: macOS text areas (AXTextArea) with scrollable content
  expose AXScrollBar children. A large plain-text NSTextView will have
  children `[AXScrollBar]` and will be falsely classified as rich text.
- **Placeholder/label overlays**: Some apps (e.g. Safari's address bar,
  some SwiftUI fields) attach an AXStaticText child as a placeholder
  label inside the text field.
- **Spell-check decorations**: Text fields with active spell checking can
  expose AXMisspelling children in some accessibility implementations.
- **Line number gutters**: Code editors that expose gutter elements as
  children of the text area will trigger the heuristic.

The consequence is that these plain-text fields are forced into keyboard
fallback mode, losing all accessibility-powered motions (word objects,
line jumps, visual mode with precise selection, etc.) even though the
underlying AX APIs would work correctly.

Conversely, the heuristic does **not** false-negative in a dangerous way:
a truly rich text field without children would be treated as plain text,
but in practice rich fields (contenteditable, NSAttributedString views)
almost always have children.

### Block cursor polling

`lib/block_cursor.lua` lines 29-35 create an `hs.timer` that fires at
60fps (every 16.67ms). Each frame calls `_renderFrame()` which:

1. Creates a **new** `AccessibilityBuffer` (line 56), which queries
   `ax.systemWideElement():attributeValue("AXFocusedUIElement")` -- an
   IPC round-trip to the accessibility server.
2. Calls `buffer:isValid()` (line 57), which makes up to 4 additional AX
   queries: `AXSelectedTextRange`, `AXRole`, `AXChildren`, plus
   `hs.application.frontmostApplication()`.
3. Calls `buffer:isAtLastVisibleCharacter()` (line 63), which queries
   `AXVisibleCharacterRange`.
4. Calls `buffer:getSelectionRange()` (line 66), which queries
   `AXSelectedTextRange` (cached from step 2 on the same buffer
   instance).
5. Calls `currentElement:parameterizedAttributeValue("AXBoundsForRange",
   ...)` (line 74), which is the most expensive single call as it
   requires the target app to compute glyph layout bounds.

In total, each frame makes approximately **6-8 cross-process AX IPC
calls**. At 60fps this is 360-480 IPC round-trips per second. Each call
involves a Mach message to the target application's accessibility server,
context switches, and serialization overhead.

The practical CPU impact: on an Apple Silicon Mac, this adds roughly
2-5% CPU to the Hammerspoon process and a measurable amount to the
target app (which must service the AX requests on its main thread). On
Intel Macs or with heavyweight apps (Chrome with many tabs, Electron
apps), the overhead can be noticeably higher. The timer runs continuously
while the block cursor is visible (i.e. the entire time the user is in
normal mode with the beta feature enabled), even if nothing on screen has
changed.

The timer is only active when `BlockCursor:show()` has been called and
stops on `BlockCursor:hide()`, which is correctly tied to entering and
exiting normal mode. But there is no frame-skip logic, no dirty-checking,
and no fallback to a lower refresh rate when the cursor position has not
changed.

### Focus watcher memory leak

`lib/focus_watcher.lua` line 3 declares `registeredPids = {}` as a
module-level local. Each time an application is activated, line 12 checks
`registeredPids[pid]` and, if not present, creates an AX observer and
stores it at line 24:

```lua
registeredPids[pid] = observer
```

Entries are **never removed**. When an application terminates, its PID
becomes invalid, the AX observer becomes a dead reference, and the entry
remains in the table. Over a long-running Hammerspoon session (days or
weeks, as is typical for a window manager), the table accumulates entries
for every application that was ever focused.

Each stale entry holds:

- A Lua reference to the observer userdata object
- The observer's internal Mach port (which may or may not be cleaned up
  by the OS when the target process exits)
- Any closure captures from the callback (line 17:
  `function() vim:exit() end`)

The `hs.application.watcher` in `focus_watcher.lua` only handles the
`activated` event (line 48). It does not listen for `terminated` events,
which would be the natural place to clean up stale entries. Similarly,
the `alreadyPatchedApps` table in `lib/utils/ax.lua` (line 43) has the
same unbounded growth pattern -- patched app entries are never evicted.

### Multiple redundant AX queries

The `AXFocusedUIElement` attribute is queried by creating a fresh
`ax.systemWideElement()` and calling
`:attributeValue("AXFocusedUIElement")` independently in three separate
code paths:

| Location | File | Line |
|----------|------|------|
| `AccessibilityBuffer:getCurrentElement()` | `lib/accessibility_buffer.lua` | 52-53 |
| `AccessibilityStrategy:getCurrentElement()` | `lib/strategies/accessibility_strategy.lua` | 106-107 |
| `getFocusedElementPosition()` | `lib/state_indicator.lua` | 35-38 |

Within a single vim operation these can all fire. For example, when the
user presses a motion key in normal mode:

1. `VimMode:fireCommandState()` (vim.lua line 354) creates an
   `AccessibilityStrategy` and calls `strategy:isValid()`, which creates
   an `AccessibilityBuffer` that queries `AXFocusedUIElement`.
2. The strategy's own `getCurrentElement()` queries it again
   independently (the strategy and buffer do not share element
   references).
3. `VimMode:updateStateIndicator()` calls `StateIndicator:render()` which
   calls `getFocusedElementPosition()`, querying `AXFocusedUIElement` a
   third time.
4. If the block cursor is active, its 60fps timer queries it yet again
   via its own `AccessibilityBuffer` instance.

Each query is a full IPC round-trip. None of these results are shared
across the three modules because each creates its own local
`systemElement` and `currentElement`. The `AccessibilityBuffer` does
cache `currentElement` within a single buffer instance (line 51: `if not
self.currentElement then ...`), but each `AccessibilityBuffer:new()`
creates a fresh instance with `currentElement = nil`.

### Error handling

AX API calls can return `nil` when the target app is unresponsive, the
focused element has been destroyed (e.g. a closed tab), or the app does
not support the requested attribute. The error handling is inconsistent:

**Protected calls (good):**

- `focus_watcher.lua` line 27: the observer creation is wrapped in
  `pcall(creator)` with error logging on failure.

**Nil-guarded calls (partial):**

- `AccessibilityBuffer:getCurrentElement()` returns `nil` if the AX
  query fails, and several methods check for this (e.g. `getValue()`
  line 118, `getSelectionRange()` line 67).
- `AccessibilityBuffer:isValid()` checks for nil element and nil
  selection before proceeding.
- `StateIndicator:getFocusedElementPosition()` checks for nil
  `systemElement`, nil `currentElement`, and nil `position`.

**Unprotected calls (crash risk):**

- `AccessibilityBuffer:getCurrentLineNumber()` (line 194) calls
  `:parameterizedAttributeValue('AXLineForIndex', ...)` directly on
  `self:getCurrentElement()`. If `getCurrentElement()` returns nil, this
  is a nil-index error (attempt to call method on nil value).
- `AccessibilityBuffer:getCurrentLineRange()` (line 205) chains through
  `getCurrentLineNumber()` and `getRangeForLineNumber()` without nil
  guards.
- `AccessibilityBuffer:getLineCount()` (line 95) calls
  `:parameterizedAttributeValue(...)` without checking if the element
  is nil.
- `AccessibilityBuffer:visibleLineRange()` (line 219) calls
  `:attributeValue("AXVisibleCharacterRange")` and then chains
  `:parameterizedAttributeValue('AXLineForIndex', ...)` -- the second
  call does not guard against the element being nil.
- `AccessibilityStrategy:setSelectionRange()` (line 128) calls
  `:setAttributeValue(...)` on `getCurrentElement()` without a nil
  check.
- `AccessibilityStrategy:getUIRole()` (line 146) calls
  `:attributeValue("AXRole")` without checking for a nil element.
- `AccessibilityStrategy:setValue()` (line 138) has a nil guard on line
  137 but then calls `self:getCurrentElement().setValue(value)` using
  dot-syntax instead of colon-syntax. This calls `setValue` as a plain
  function rather than a method, passing the return value of
  `getCurrentElement()` as the first positional argument instead of as
  `self`. The correct call would be
  `self:getCurrentElement():setValue(value)`.
- `BlockCursor:_renderFrame()` calls `buffer:getSelectionRange()` (line
  66) and accesses `range.location` (line 68) without checking if
  `range` is nil. Although `isValid()` above should have caught most nil
  cases, a race condition between the validity check and the range fetch
  could still produce nil if the focused element changes between calls.

The general pattern is that methods called from `isValid()` have nil
guards, but methods called **after** validation (assuming the buffer is
valid) do not re-check, creating a TOCTOU (time-of-check to time-of-use)
window where the focused element can change between the validity check
and the actual operation.

### The bannedApps list

The hardcoded `bannedApps` table in `lib/accessibility_buffer.lua`
contains three entries:

```lua
local bannedApps = {
  Code = true,    -- VS Code
  Notion = true,  -- Notion cells
  Slack = true    -- AXSelectedTextRange always returns {0, 0}
}
```

This list is incomplete. The `AppWatcher` in `lib/app_watcher.lua` has a
separate `disabled` table (line 27) for apps where VimMode is entirely
disabled (MacVim, iTerm, iTerm2, Terminal). These two lists serve
different purposes: `bannedApps` forces fallback mode while `disabled`
turns VimMode off entirely. There is no single authoritative list of
problematic apps, and users must know to use the correct API
(`useFallbackMode` vs `disableForApp`) for each case.

Apps that are known to have broken or partial accessibility support but
are missing from `bannedApps`:

- **Discord** -- Electron-based, same class of issues as Slack (message
  input AXValue reads return stale content)
- **Microsoft Teams (new)** -- Electron-based, AXSelectedTextRange
  reports incorrect positions similar to Slack
- **Obsidian** -- Electron-based, AXSelectedTextRange can lag behind
  actual cursor position
- **Figma** -- canvas-based rendering, text fields are custom and do not
  expose standard AX attributes
- **WhatsApp Desktop** -- Electron-based, limited AX support in message
  composer
- **Telegram Desktop** -- custom Qt-based text input with incomplete AX
  implementation
- **1Password 8** -- Electron-based, AX write operations
  (`setAttributeValue`) fail silently

The list also relies on exact application name matching (line 138:
`currentApp:name()`), which is fragile -- app names can change across
versions (e.g. "Slack" vs "Slack Helper"), and localized macOS installs
may report different names for some apps.

---

## 6. State Machine Edge Cases

The FSM is defined in `lib/state.lua`, powered by the engine in
`lib/utils/statemachine.lua` (a modified fork of
[kyleconroy/lua-state-machine](https://github.com/kyleconroy/lua-state-machine)),
consumed by `lib/vim.lua`, and driven by key handlers in `lib/modal.lua`.

### 6.1 Complete state/event map and missing transitions

The FSM defines 6 states and 6 events. The full transition table is:

| From \ Event        | enterNormal | enterInsert | enterVisual | enterOperator | enterMotion | fire |
|---------------------|:-----------:|:-----------:|:-----------:|:-------------:|:-----------:|:----:|
| insert-mode         | Y           | --          | --          | --            | --          | --   |
| normal-mode         | Y (self)    | Y           | Y           | Y             | Y           | --   |
| visual-mode         | Y           | Y           | **MISSING** | Y             | Y           | Y    |
| operator-pending    | Y           | Y           | --          | --            | Y           | --   |
| entered-motion      | --          | --          | --          | --            | --          | Y    |
| firing              | Y           | Y           | Y           | --            | --          | --   |

**Missing: `enterVisual` from `visual-mode`.** The `enterVisual` event can
only be triggered from `normal-mode` or `firing`. If code calls
`state:enterVisual()` while already in visual mode, the FSM silently
returns `false` from `self:can(name)` and does nothing. This is not
necessarily a bug (Vim itself exits visual mode on `v`), but the modal
binds `v` only in the `normal` context so this path is unreachable in
practice. The gap becomes relevant if any future code calls
`state:enterVisual()` from a visual-mode callback -- it will silently fail.

**Missing: `enterNormal` from `entered-motion`.** The `entered-motion`
state is transient: the `onenterMotion` callback immediately calls
`self:fire()`, so the FSM should never rest in `entered-motion`. However,
if `self:fire()` fails (because of an `asyncState` conflict), there is no
`enterNormal` escape hatch from `entered-motion`. The user would be stuck
with no way to recover except restarting Hammerspoon.

**Missing: `enterInsert` from `entered-motion`.** Same situation. If the
transient state ever persists, there is no `enterInsert` or `enterNormal`
transition defined to escape it.

### 6.2 Async state machine complexity

The `create_transition()` function in `statemachine.lua` implements a
three-phase transition protocol using `self.asyncState`:

1. **Phase 1** (`asyncState == NONE`): Run `onbefore*` and `onleave*`
   callbacks. Set `asyncState` to `"{event}WaitingOnLeave"`. If
   `onleave*` does not return `ASYNC`, immediately recurse to phase 2.
2. **Phase 2** (`asyncState == "{event}WaitingOnLeave"`): Set
   `self.current` to the target state. Run `onenter*` callback. Set
   `asyncState` to `"{event}WaitingOnEnter"`. If `onenter*` does not
   return `ASYNC`, immediately recurse to phase 3.
3. **Phase 3** (`asyncState == "{event}WaitingOnEnter"`): Run `onafter*`
   and `onstatechange` callbacks. Reset `asyncState` to `NONE`.

No callback in the VimMode.spoon codebase ever returns `ASYNC`, so all
transitions complete synchronously through all three recursive calls in a
single invocation. The `asyncState` variable passes through
`"{event}WaitingOnLeave"` and `"{event}WaitingOnEnter"` transiently
within the same call stack.

**Stuck `asyncState` scenario:** If a callback were to throw an error
(e.g. an unprotected Lua error in `onenterNormal` or `onfire`), the
recursive chain would unwind without reaching phase 3. The `asyncState`
would remain set to either `"{event}WaitingOnLeave"` or
`"{event}WaitingOnEnter"`. Every subsequent call to *any* transition would
hit the `else` branch at line 85 of `statemachine.lua`, which forcibly
resets `asyncState` to `NONE` and retries. This is a recovery mechanism,
but it means:
- The `onstatechange` callback for the failed transition is never called,
  so `updateStateIndicator()` is skipped and the UI indicator becomes
  stale.
- The `self.current` state may or may not have been updated (it is updated
  in phase 2 before the `onenter*` callback runs), so a failure in
  `onenter*` leaves `self.current` pointing at the *target* state even
  though the enter callback did not complete.

### 6.3 Re-entrant transitions from callbacks

The `onenterMotion` and `onfire` callbacks both initiate new transitions
from within a transition:

```lua
-- onenterMotion calls fire() during the enterMotion transition
onenterMotion = function(self, _, _, _, motion)
  vim.commandState.motion = motion
  self:fire()          -- re-entrant transition
end

-- onfire calls enterNormal(), enterVisual(), or exitAsync()
onfire = function(self)
  local result = vim:fireCommandState()
  if result.mode == "visual" then
    if result.hadOperator then
      self:enterNormal()   -- re-entrant transition
    else
      self:enterVisual()   -- re-entrant transition
    end
  else
    if result.transition == "normal" then self:enterNormal()
    else vim:exitAsync() end
  end
end
```

This works because the recursive call happens during phase 3 (the
`onafter*` / `on{event}` handler), at which point `asyncState` is set to
`"{event}WaitingOnEnter"`. When the inner transition calls
`create_transition(newName)`, it enters with `asyncState` ==
`"{oldEvent}WaitingOnEnter"`, which does not match `NONE` and does not
match `"{newName}WaitingOnLeave"` or `"{newName}WaitingOnEnter"`. It
falls into the `else` branch at line 85, which checks for any
`WaitingOnLeave` or `WaitingOnEnter` substring and forcibly resets
`asyncState` to `NONE` before retrying.

**Consequence:** The outer transition's phase 3 never completes normally.
Specifically, `onstatechange` for the *outer* event is skipped because the
inner transition hijacks `asyncState`. This means
`vim:updateStateIndicator()` is called for the final state but not for the
intermediate `firing` state. In practice this is harmless since the
intermediate state is never user-visible, but it means the
`onstatechange` callback fires fewer times than the number of transitions.

**Deeper concern:** The `onfire` callback runs during the `fire`
transition's phase 3. It calls `self:enterNormal()`, which starts a
*new* full transition. That new transition's `onenterNormal` callback
calls `vim:enterModal('normal')`, which modifies the modal state. If
`onenterNormal` itself triggered another transition (it does not today),
the nesting depth would increase further. The FSM has no guard against
infinite re-entrant depth.

### 6.4 Modal context vs FSM state desynchronization

The FSM's `self.current` and the modal's `self.activeContext` are updated
independently:

| FSM State          | Expected Modal Context |
|--------------------|----------------------|
| `insert-mode`      | `nil` (modal exited) |
| `normal-mode`      | `"normal"`           |
| `visual-mode`      | `"visual"`           |
| `operator-pending` | `"operatorPending"`  |
| `entered-motion`   | (transient)          |
| `firing`           | (transient)          |

Desync paths:

1. **Failed silent transition:** If a transition call returns `false`
   (e.g. calling `enterVisual` from `operator-pending`, which is not
   defined), the FSM state is unchanged but any modal changes made
   *before* the transition (e.g. in `operatorNeedingChar` or
   `motionNeedingChar`) may have already been applied. In
   `motionNeedingChar` (line 111 of `modal.lua`), the code calls
   `vim:exitModalAsync()` to leave the modal *before* the transition.
   If the subsequent `enterMotion` transition were to fail, the modal
   would be exited but the FSM would still be in `operator-pending`.
   The user would have no active modal and no way to type commands.

2. **The `g` and `inTextObject` sub-contexts:** Pressing `g` or `i` in
   normal or operator-pending mode calls `vim:enterModal('g')` or
   `vim:enterModal('inTextObject')`, switching the modal context away
   from the current mode without any FSM transition. If the user presses
   `escape` in these sub-contexts, `vim:cancel()` fires
   `state:enterNormal()`, which calls `vim:enterModal('normal')` and
   resyncs. But if the motion bound in the sub-context fires and the
   `onfire` callback transitions to visual mode, the modal context is set
   to `"visual"` by the `onenterVisual` callback, correctly overriding
   the sub-context. This path works but is fragile: any new sub-context
   that does not properly clean up can desync.

3. **`exitModalAsync()` timing:** `motionNeedingChar` and
   `operatorNeedingChar` both call `vim:exitModalAsync()` which schedules
   modal exit after 5ms. During that 5ms window, the modal is still
   active in its old context. A fast typist could trigger another key
   handler in that window. After the 5ms, the modal exits, but then
   `onChar` calls `vim:enterModal(previousContext)` to re-enter. If the
   FSM state has changed during the gap (e.g. the user pressed `escape`
   during the 5ms), the modal is re-entered with a stale context.

### 6.5 Error handling in the `onfire` callback

The `onfire` callback calls `vim:fireCommandState()`, which:
1. Constructs an `AccessibilityStrategy` and a `KeyboardStrategy`.
2. Calls `findFirst()` to pick the first valid strategy.
3. Calls `strategy:fire()`.
4. Reads `operator.getModeForTransition()` or
   `motion.getModeForTransition()`.

**If `strategy:fire()` throws an error** (e.g. the accessibility element
is stale and `attributeValue()` returns nil, which is then indexed), the
`onfire` callback aborts. The FSM is left in the `firing` state with
`asyncState` stuck at `"fireWaitingOnEnter"`. No subsequent `onfire`
phase-3 cleanup runs, so `asyncState` is never reset to `NONE`.

On the next keypress, any transition attempt will hit the `else` branch
in `create_transition()` and forcibly reset `asyncState`, recovering.
However, the FSM's `self.current` is now `firing`, and the only valid
outbound transitions from `firing` are `enterNormal`, `enterInsert`, and
`enterVisual`. If the user presses `escape`, `vim:cancel()` calls
`state:enterNormal()`, which is valid from `firing` and will recover.
But if no recovery key is pressed, the user is effectively stuck.

**If `getModeForTransition()` returns an unexpected value** (not
`"normal"` and not `"insert"`), the `onfire` callback falls through to
`vim:exitAsync()`, which is the `else` branch. This is safe but means
any typo in a new operator's `getModeForTransition()` silently exits to
insert mode rather than raising an error.

**If `findFirst()` returns nil** (neither strategy is valid), line 367
of `vim.lua` calls `strategy:fire()` on `nil`, producing a Lua error.
This triggers the stuck-in-`firing` scenario described above.
`KeyboardStrategy:isValid()` inherits from `Strategy.isValid()` which
always returns `true`, so in practice `findFirst()` always returns the
keyboard strategy as a fallback. But if `KeyboardStrategy` is ever
changed to validate more strictly, this nil crash becomes reachable.

### 6.6 Race between `exitAsync` and other transitions

`vim:exitAsync()` (line 303 of `vim.lua`) schedules a 5ms timer that
calls `self:exit()`, which calls `self.state:enterInsert()`. This timer
runs asynchronously after the current callback returns.

**Race scenario 1: rapid mode toggle.** In normal mode, pressing `i`
calls `vim:exitAsync()`. The FSM is still in `normal-mode` when the
handler returns (the `enterInsert` has not happened yet). If the user
somehow triggers `enterNormal` before the 5ms elapses (e.g. through the
key sequence like `jk`), the FSM transitions to `normal-mode` (a no-op
self-transition). Then the timer fires and calls `state:enterInsert()`,
yanking the user back to insert mode unexpectedly. This is a genuine
race condition: fast `i` -> `escape`/sequence input can flicker between
modes.

**Race scenario 2: `exitModalAsync` vs `enterModal` in char-waiting.**
`motionNeedingChar` (line 110 of `modal.lua`) calls
`vim:exitModalAsync()` (5ms delay) and then starts a `WaitForChar`
eventtap. When the char arrives, the `onChar` callback calls
`vim:enterModal(previousContext)` and then schedules *another* 5ms timer
for `vim:enterMotion(motion)`. If the first `exitModalAsync` timer fires
*after* the `enterModal` call re-enters the modal, it will call
`vim:exitAllModals()` and tear down the modal that was just re-entered.
This is unlikely for human input (the `WaitForChar` blocks until a
keypress, which takes far longer than 5ms), but is possible with
synthetic events or in automated tests.

**Race scenario 3: stacking `exitAsync` calls.** Multiple commands
that call `vim:exitAsync()` in rapid succession (e.g. holding `o` with
key repeat) will each schedule independent 5ms timers. Each timer
captures `self` via closure and calls `self:exit()`. If the first timer
fires and transitions to `insert-mode`, the second timer fires and
calls `state:enterInsert()` from `insert-mode`, which has no defined
transition and returns `false`. This is harmless but wasteful.

### 6.7 Summary of stuck-state risks

| Scenario | Stuck State | Recovery | Severity |
|----------|-------------|----------|----------|
| Error in `onfire` callback | `firing` + stale `asyncState` | Next transition auto-resets `asyncState`; `escape` transitions from `firing` to `normal-mode` | Medium |
| Error in `onenterMotion` before `self:fire()` | `entered-motion` with no outbound transitions except `fire` | No defined escape; requires Hammerspoon restart | High |
| `exitAsync` timer fires after `enterNormal` | Normal-mode overridden to insert-mode | User must re-enter normal mode | Low (timing dependent) |
| `exitModalAsync` timer fires after `enterModal` re-entry | Modal torn down while FSM expects it active | Keys stop responding; `enterNormal` on next attempt will re-enter modal | Medium |
| `findFirst()` returns nil in `fireCommandState()` | `firing` + Lua error | Same as error-in-`onfire` | Medium |

---

## 7. Dead and Duplicated Code

### Duplicate method definitions

Lua silently overwrites a method when it is defined twice on the same
table. Only the last definition takes effect; the first is dead code.

#### `AccessibilityBuffer:getCurrentLineNumber()` -- defined twice

`lib/accessibility_buffer.lua` lines 84-93 (first definition) and
lines 194-203 (second definition):

```lua
-- First definition (line 84) -- DEAD, silently overwritten
function AccessibilityBuffer:getCurrentLineNumber()
  local number = self
    :getCurrentElement()
    :parameterizedAttributeValue(
      'AXLineForIndex',
      self:getCurrentLineRange().location
    ) or 0
  return number + 1
end

-- Second definition (line 194) -- this is the one that runs
function AccessibilityBuffer:getCurrentLineNumber()
  local axLineNumber = self:getCurrentElement():parameterizedAttributeValue(
    'AXLineForIndex',
    self:getCaretPosition()
  )
  if not axLineNumber then return 1 end
  return axLineNumber + 1
end
```

The two implementations differ in what index they pass to `AXLineForIndex`:
the first uses `self:getCurrentLineRange().location` (beginning of the
current line), the second uses `self:getCaretPosition()` (the actual cursor
position). The first definition would create a circular call since
`getCurrentLineRange` calls `getCurrentLineNumber`, so only the second
definition (which breaks the cycle by using `getCaretPosition`) is correct.
The first definition is dead code.

### Methods never called

These methods are defined but never invoked from any production code path.
Some are called only from tests; some are not called at all.

#### `AccessibilityBuffer:enableLiveApplicationPatches()` (line 271)

Defined on `lib/accessibility_buffer.lua` line 271. Never called anywhere
in the codebase. The same functionality is provided by `lib/utils/ax.lua`
via `axUtils.patchCurrentApplication()`, which is invoked by the hot
patcher (`lib/hot_patcher.lua`). This method is entirely dead.

#### `AccessibilityBuffer.getCurrentApplication()` (line 259)

Defined as a static method on `lib/accessibility_buffer.lua` line 259.
Only called internally by `enableLiveApplicationPatches()` (line 272),
which is itself dead. Therefore this method is also dead.

#### `AccessibilityBuffer:getLineCount()` (line 95)

Defined on `lib/accessibility_buffer.lua` line 95. This is an
AX-specific override of `Buffer:getLineCount()`. It is never called
directly. The base `Buffer:getLineCount()` (line 134 of `buffer.lua`)
is called from `Buffer:isOnLastLine()`, but `AccessibilityBuffer`
instances use the second `getCurrentLineNumber()` definition which
bypasses line counting entirely. No code path calls `getLineCount()` on
an `AccessibilityBuffer` instance.

#### `AccessibilityStrategy:setValue()` (line 136)

Defined on `lib/strategies/accessibility_strategy.lua` line 136. Never
called anywhere in the codebase. Additionally, it has a bug: it calls
`self:getCurrentElement().setValue(value)` using dot syntax instead of
colon syntax, which would pass `value` as `self` to the AX method.

#### `AccessibilityStrategy:getValue()` (line 131)

Defined on `lib/strategies/accessibility_strategy.lua` line 131. Never
called anywhere in the codebase. The strategy uses
`AccessibilityBuffer:getValue()` instead when it needs field contents.

#### `AccessibilityStrategy:getUIRole()` (line 145)

Defined on `lib/strategies/accessibility_strategy.lua` line 145. Only
called by `AccessibilityStrategy:isInTextField()` (line 149), which is
itself never called. Both are dead.

#### `AccessibilityStrategy:isInTextField()` (line 149)

Defined on `lib/strategies/accessibility_strategy.lua` line 149. Never
called. Validation goes through `AccessibilityBuffer:isValid()` which
calls `AccessibilityBuffer:isInTextField()` (a different method on a
different class). This is duplicated, dead logic.

#### `Config:disableBetaFeature()` (line 40)

Defined on `lib/config.lua` line 40. Never called anywhere in the
codebase -- not in production code, not in tests, not in the README.
Only `enableBetaFeature` and `isBetaFeatureEnabled` are used.

#### `AppWatcher:stop()` (line 60)

Defined on `lib/app_watcher.lua` line 60. Never called. The app watcher
is created and started in `vim.lua` line 79 but there is no code path
that stops it.

#### `Buffer:getContentsBeforeSelection()` and `Buffer:getContentsAfterSelection()`

Defined on `lib/buffer.lua` lines 110-124. Called only from test code
(`spec/buffer_spec.lua`). No production code path uses either method.

#### `Buffer:setSelectionRangeFromSelection()` (line 68)

Defined on `lib/buffer.lua` line 68. Never called anywhere -- not in
production code, not in tests. The codebase uses `setSelectionRange()`
(which takes `location, length`) or `createNew()` instead.

#### `CommandState:getRepeatTimes()` (line 38)

Defined on `lib/command_state.lua` line 38. Never called. This method
multiplies `operatorTimes * motionTimes` to compute a repeat count, but
since the count/repeat feature is commented out (see below), nothing
ever invokes it.

#### `Operator:getModifiedBuffer()` -- defined on all operators, never called at runtime

Each operator (`Delete`, `Replace`, `Yank`) defines a `getModifiedBuffer()`
method. These are only called from test code (`spec/operators/`). The
production code path in `AccessibilityStrategy:fire()` calls
`operator:modifySelection()` instead. The `getModifiedBuffer()` methods
appear to be a parallel, test-only implementation of the operator logic.

### Commented-out code

#### Count/repeat digit bindings in `modal.lua` (lines 155-167)

`lib/modal.lua` lines 155-167 contain the `bindCountsToModal` function
which immediately returns without binding anything, followed by nine
commented-out lines:

```lua
modal.bindCountsToModal = function(mdl, name)
  -- disable counts for now
  return mdl
    -- :bindWithRepeat({}, '1', pushDigitTo(name, 1))
    -- :bindWithRepeat({}, '2', pushDigitTo(name, 2))
    -- ...through 9...
end
```

This represents a complete count/repeat feature (e.g. `3dw` to delete
three words). The supporting infrastructure is fully wired:

- `CommandState:pushCountDigit()` (`lib/command_state.lua` line 59) --
  accumulates digits into a count
- `CommandState:getRepeatTimes()` (`lib/command_state.lua` line 38) --
  computes the total repeat count
- `numberUtils.pushDigit()` (`lib/utils/number_utils.lua` line 3) --
  shifts and adds digits
- `VimMode:pushDigitTo()` (`lib/vim.lua` line 348) -- passes digits to
  the command state
- The `0` key binding in `bindMotionsToModal` (line 173) already checks
  `vim.commandState:getCount(type)` to distinguish "go to line beginning"
  from "append digit 0 to count"

All of this infrastructure is dead because the digit bindings are
commented out. The `0` key's count check (line 173) is unreachable --
`getCount` always returns `nil` since no digits are ever pushed.

### Unused imports and dofile calls

#### `lib/vim.lua` line 17: `local ax = dofile(...)` -- unused

The `ax` variable is assigned but never referenced in `vim.lua`. The
accessibility module is accessed through `AccessibilityBuffer` and
`AccessibilityStrategy` instead.

#### `lib/vim.lua` line 18: `dofile(... "lib/utils/benchmark.lua")` -- side-effect only

This `dofile` call loads the benchmark utility purely for its
side effect of defining the global function `vimBenchmark`. However,
`vimBenchmark` is never called anywhere in the codebase. The import and
the global function are both dead.

#### `lib/vim.lua` line 19: `dofile(... "lib/utils/browser.lua")` -- redundant

The browser utils module is loaded here but the return value is
discarded. The module is also loaded separately by
`accessibility_buffer.lua` (line 6) where it is actually used. This
`dofile` call in `vim.lua` is redundant.

#### `lib/strategies/accessibility_strategy.lua` line 2: `local inspect = ...` -- unused

The `inspect` variable is assigned from `hs.inspect.inspect` but never
referenced in the file. It was likely used during debugging and left
behind.

#### `lib/contextual_modal.lua` lines 2 and 4: unused imports

`local stringUtils` and `local utf8` are loaded but never referenced in
the file. Only `Registry` and `tableUtils` are actually used.

#### `lib/contextual_modal.lua` line 8: `mapToList` function -- dead

The local function `mapToList` is defined but never called anywhere in
the file.

### Unused files

#### `lib/utils/visible_range.lua`

The file contains a single line: `local VisibleRange = {}`. It defines
an empty table and returns nothing. No file imports it. Entirely dead.

#### `lib/utils/log.lua`

A vendored logging library (rxi/log.lua). Only imported by
`spec/spec_helper.lua` (line 5) for tests. No production code loads or
uses it. The production code uses `vimLogger` (an `hs.logger` instance)
instead.

#### `lib/utils/inspect.lua`

A vendored table inspector library. Only imported by
`spec/spec_helper.lua` (line 1). No production code loads it (the
accessibility strategy file imports `hs.inspect.inspect` from
Hammerspoon's built-in instead).

### Deprecated methods

#### `VimMode:enableKeySequence()` (`lib/vim.lua` line 197)

Explicitly marked as deprecated with an `alertDeprecation()` call.
Replaced by `VimMode:enterWithSequence()`. Still present for backward
compatibility.

No other methods are explicitly marked as deprecated, but several
public-API methods on `VimMode` exist solely in the README/installer
examples and would be candidates for deprecation if the features they
control are removed (e.g. `setAlertFont`, `disableHotPatcher`).

### Feature flags for incomplete or suspect features

#### `fallback_only_urls` beta feature

Gated behind `config:isBetaFeatureEnabled('fallback_only_urls')` in
`lib/accessibility_buffer.lua` line 160. The feature works by running
AppleScript to get the current browser URL and matching it against
patterns. This has two reliability issues:

1. The AppleScript calls in `lib/utils/browser.lua` leak globals
   (`result`, `url`) on every invocation.
2. The URL fetch fires on every keystroke in normal mode (as part of
   `isValid()` -> `onFallbackOnlyUrl()`), adding AppleScript IPC
   latency to every keypress when a browser is frontmost.

The feature functions but remains permanently in beta.

#### `block_cursor_overlay` beta feature

Gated behind `config:isBetaFeatureEnabled('block_cursor_overlay')` in
`lib/vim.lua` lines 242 and 248. The feature works by polling the
accessibility API at 60fps (`lib/block_cursor.lua` line 29) to draw a
canvas overlay. It functions for apps with good `AXBoundsForRange`
support but fails silently for Chrome (which returns zero-sized bounds).
Remains permanently in beta.

### Duplicated logic

#### Yank: clipboard copy in both `modifySelection` and `getModifiedBuffer`

`lib/operators/yank.lua` implements the same clipboard-copy logic in two
methods:

```lua
-- modifySelection (line 5) -- called at runtime
function Yank:modifySelection(buffer, rangeStart, rangeFinish)
  local stringStart, stringFinish = rangeStart + 1, rangeFinish + 1
  local toCopy = utf8.sub(buffer:getValue(), stringStart, stringFinish)
  hs.pasteboard.setContents(toCopy)
end

-- getModifiedBuffer (line 14) -- called only from tests
function Yank.getModifiedBuffer(_, buffer, rangeStart, rangeFinish)
  local stringStart, stringFinish = rangeStart + 1, rangeFinish + 1
  local toCopy = utf8.sub(buffer:getValue(), stringStart, stringFinish)
  hs.pasteboard.setContents(toCopy)
  return buffer
end
```

The two methods extract and copy the same substring. If one is changed
(e.g. to fix a UTF-8 bug), the other must be changed in lockstep or
tests will pass while production silently remains broken (or vice
versa).

#### `getCurrentElement()` duplicated between AccessibilityBuffer and AccessibilityStrategy

Both `AccessibilityBuffer:getCurrentElement()` (line 50) and
`AccessibilityStrategy:getCurrentElement()` (line 104) contain identical
logic: get `ax.systemWideElement()`, then read `AXFocusedUIElement`.
Each caches the result on `self.currentElement`. The strategy does not
delegate to the buffer; they are independent copies.

#### `isInTextField` duplicated between AccessibilityBuffer and AccessibilityStrategy

`AccessibilityBuffer:isInTextField()` (line 263) delegates to
`axUtils.isTextField()`. `AccessibilityStrategy:isInTextField()` (line
149) re-implements the check inline by reading `AXRole` directly. The
strategy version is never called (see dead methods above), but the
duplication means any change to the `isTextField` logic must be
replicated in the strategy or the dead code will become wrong if it is
ever revived.

#### `debugEventType` function in `app_watcher.lua` (line 3) -- dead helper

A local function that maps `hs.application.watcher` event type constants
to human-readable strings. Never called anywhere in the file. Likely a
leftover debugging aid.

---

## 8. Minor Bugs

### Punctuation set typo

`lib/utils/string_utils.lua` line 8: the punctuation set contains
`" '"` (space-then-single-quote) instead of `"'"` (just single-quote).
This means a bare `'` is never recognized as punctuation by
`stringUtils.isPunctuation()`. Affects word motion boundary detection:
`w`/`b`/`e` will not stop at single quotes.

### isWhitespace only checks space

`lib/utils/string_utils.lua` line 16:

```lua
function stringUtils.isWhitespace(char)
  return char == " "
end
```

Tabs (`\t`), vertical tabs, form feeds, and other Unicode whitespace
characters are not recognized. This affects word motions (`w`, `b`, `e`,
`W`, `B`) in tab-indented text: the cursor will treat tabs as non-blank
printable characters and not stop at tab/word boundaries correctly.

### AccessibilityBuffer:new() called without vim arg

`lib/strategies/accessibility_strategy.lua` lines 56-58:

```lua
local newBuffer = AccessibilityBuffer
  :new()
  :setSelectionRange(start, 0)
```

`AccessibilityBuffer:new()` expects a `vim` argument (line 32 of
`accessibility_buffer.lua`) but none is passed. `buffer.vim` is `nil`.
This specific code path only calls `setSelectionRange` and
`resetToBeginningOfLineForIndex`, which work because they only use
`self.currentElement` (inherited from the prototype). However, if the
code ever calls `isBannedApp()` or `onFallbackOnlyUrl()` on this
buffer, it will crash with `attempt to index a nil value (self.vim)`.

### AccessibilityStrategy:setValue() dot-vs-colon bug

`lib/strategies/accessibility_strategy.lua` line 138:

```lua
function AccessibilityStrategy:setValue(value)
  if not self:getCurrentElement() then return end
  self:getCurrentElement().setValue(value)  -- BUG: dot not colon
end
```

Uses `.setValue(value)` (dot syntax) instead of `:setValue(value)`
(colon syntax). In Lua, dot syntax does not pass the object as `self`,
so the AX element receives `value` as `self` instead of as the first
argument. This would silently do the wrong thing or crash. The method
is currently dead code (never called), so this bug has no runtime
impact today.

### `back_word.lua` leading space in modifier

`lib/motions/back_word.lua` returns `{ ' alt' }` (with a leading space)
instead of `{ 'alt' }` as the modifier for the keyboard fallback
movement. This means the `b` motion in fallback mode either fires a
bare Left arrow (without Alt) or does nothing, depending on how
Hammerspoon handles unrecognized modifier strings. Compare with
`back_big_word.lua` which correctly uses `{ 'alt' }`.

### `replace.lua` crashes in fallback mode

`lib/operators/replace.lua` line 49:

```lua
function Replace:getKeys()
  -- TODO support in bootleg mode
  return nil
end
```

In `KeyboardStrategy:fireOperator()` (line 55 of
`keyboard_strategy.lua`), the return value is passed directly to
`pairs()`. When `getKeys()` returns `nil`, Lua throws:
`bad argument #1 to 'pairs' (table expected, got nil)`. This is a
crash, not a silent failure. Any `r{char}` in an app without
accessibility support will terminate the Hammerspoon callback.

### Screen dimmer affects all screens

`lib/screen_dimmer.lua` line 22:

```lua
hs.screen.primaryScreen():setGamma(whiteShift, blackShift)
```

Only dims the primary screen. On multi-monitor setups, secondary screens
are not dimmed when entering normal mode, giving inconsistent visual
feedback. The restore (`hs.screen.restoreGamma()`) restores all screens
globally, which is correct.

### `LineEnd` motion mode comment contradicts behavior

`lib/motions/line_end.lua` lines 17-23:

```lua
-- the vim manual says this is an inclusive motion, but I swear
-- it *behaves* like an exclusive motion, so I'm keeping it this way
-- for now as it feels more correct.
mode = 'exclusive',
```

In vim, `$` is documented as inclusive (`d$` deletes through the last
character). Using `exclusive` mode means `d$` will leave the last
character on the line undeleted. This is a semantic difference from
real vim that users may notice.

### `Selection:getCharRange` returns a half-open range

`lib/selection.lua` line 31:

```lua
function Selection:getCharRange()
  return {
    start = self.location,
    finish = self:positionEnd()  -- location + length
  }
end
```

This returns `finish = location + length`, which is a half-open range
(the character at `finish` is NOT included). But `visualUtils.getNewRange`
and `AccessibilityStrategy:fire()` treat `range.finish` as inclusive in
some contexts and exclusive in others, creating off-by-one errors in
visual mode range expansion.
