#!/usr/bin/env bash
# Destroy a space chosen by selector, moving its windows to the space
# immediately before it first (falls back to the next space only if
# there's nothing before it, e.g. destroying the first space on a display).
#
# Usage: destroy_space_by.sh <selector>
#   selector: a space index, or one of: first last next prev recent

sel="$1"
if [ -z "$sel" ]; then
    echo "usage: $(basename "$0") <index|first|last|next|prev|recent>" >&2
    exit 1
fi

# resolve the target space via yabai's own selector semantics
target_json=$(/opt/homebrew/bin/yabai -m query --spaces --space "$sel") || exit 1
tid=$(echo "$target_json" | /opt/homebrew/bin/jq -r '.index')
disp=$(echo "$target_json" | /opt/homebrew/bin/jq -r '.display')

# find the space immediately before it on the same display
before=$(/opt/homebrew/bin/yabai -m query --spaces \
    | /opt/homebrew/bin/jq -r "[.[] | select(.display == $disp and .index < $tid)] | max_by(.index).index // empty")

# nothing before it (target is first on this display) -> fall back to next
if [ -z "$before" ]; then
    before=$(/opt/homebrew/bin/yabai -m query --spaces \
        | /opt/homebrew/bin/jq -r "[.[] | select(.display == $disp and .index > $tid)] | min_by(.index).index // empty")
fi

# bail if this is the only space on the display
[ -z "$before" ] && exit 0

# move all windows off the target space before destroying it
wins=$(/opt/homebrew/bin/yabai -m query --windows --space "$tid" | /opt/homebrew/bin/jq -r '.[].id')
for w in $wins; do
    /opt/homebrew/bin/yabai -m window "$w" --space "$before"
done

/opt/homebrew/bin/yabai -m space "$tid" --destroy

# destroying a space shifts every space above it down by one index,
# so correct for that only when we fell back to a "next" target
if [ "$before" -gt "$tid" ]; then
    before=$((before - 1))
fi

/opt/homebrew/bin/sketchybar --trigger space_change
/opt/homebrew/bin/sketchybar --trigger space_windows_change