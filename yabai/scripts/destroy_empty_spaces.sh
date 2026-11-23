#!/usr/bin/env bash
set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq
LOCK_DIR="${TMPDIR:-/tmp}/prune-empty-spaces.lock"

log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*"; }

for bin in "$YABAI" "$JQ"; do
  [ -x "$bin" ] || {
    log "missing $bin"
    exit 1
  }
done

# Prevent overlapping runs (e.g. rapid skhd presses).
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  log "already running, exiting"
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

# A window is real unless it's an AXSystemDialog panel (menu bar managers,
# overlays, helper HUDs) or Finder's untitled desktop surface.
REAL_WINDOW_DEF='
  def real_window:
      (.subrole // "") != "AXSystemDialog"
      and ((.app // "") != "Finder" or ((.title // "") != ""));
'

spaces_json=$("$YABAI" -m query --spaces) || {
  log "yabai query failed (is it running?)"
  exit 1
}
windows_json=$("$YABAI" -m query --windows) || {
  log "window query failed"
  exit 1
}

# Candidates: no real windows, not focused, not the only space on its display.
# Highest index first, so destroying one doesn't shift the indices still to come.
candidates=$("$JQ" -rn \
  --argjson spaces "$spaces_json" \
  --argjson windows "$windows_json" \
  "$REAL_WINDOW_DEF"'
    ([$windows[] | select(real_window) | .space] | unique) as $occupied
    | [ $spaces[]
        | select(.index as $i | $occupied | any(. == $i) | not)
        | select((.["has-focus"] // false) | not)
        | select(.display as $d | [$spaces[] | select(.display == $d)] | length > 1)
        | .index
      ]
    | sort | reverse | .[]
') || {
  log "failed to evaluate candidates"
  exit 1
}

if [ -z "$candidates" ]; then
  log "no empty spaces"
  exit 0
fi

while IFS= read -r idx; do
  [ -n "$idx" ] || continue

  # Re-check right before destroying in case a window appeared since the snapshot.
  space_windows=$("$YABAI" -m query --windows --space "$idx") || {
    log "space $idx query failed, skipping"
    continue
  }
  if printf '%s' "$space_windows" | "$JQ" -e "$REAL_WINDOW_DEF"' any(.[]; real_window)' >/dev/null 2>&1; then
    log "space $idx now has windows, skipping"
    continue
  fi

  log "destroying empty space $idx"
  "$YABAI" -m space "$idx" --destroy || log "failed to destroy space $idx"
done <<<"$candidates"
