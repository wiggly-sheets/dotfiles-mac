#!/usr/bin/env bash
# Destroy the current space, moving its windows to the nearest
# neighboring space (previous, else next) before removing it.

cur=$(/opt/homebrew/bin/yabai -m query --spaces --space | /opt/homebrew/bin/jq -r ".index")
disp=$(/opt/homebrew/bin/yabai -m query --spaces --space | /opt/homebrew/bin/jq -r ".display")

# collect all spaces on this display
spaces=$(/opt/homebrew/bin/yabai -m query --spaces \
    | /opt/homebrew/bin/jq -r ".[] | select(.display == $disp) | .index" \
    | sort -n)

prev=""
next=""

# find prev + next relative to current
for s in $spaces; do
    if [ "$s" -lt "$cur" ]; then
        prev=$s
    elif [ -z "$next" ] && [ "$s" -gt "$cur" ]; then
        next=$s
    fi
done

# pick target space
target=$prev
[ -z "$target" ] && target=$next

# if there is no target, bail (only one space left)
[ -z "$target" ] && exit 0

# move ALL windows on current space to target BEFORE destroying
wins=$(/opt/homebrew/bin/yabai -m query --windows --space "$cur" | /opt/homebrew/bin/jq -r ".[].id")
for w in $wins; do
    /opt/homebrew/bin/yabai -m window "$w" --space "$target"
done

# destroy space
/opt/homebrew/bin/yabai -m space "$cur" --destroy

# destroying a space shifts every space above it down by one index,
# so if our target was ahead of the destroyed space, correct for it
if [ "$target" -gt "$cur" ]; then
    target=$((target - 1))
fi

# focus target (windows are already there)
/opt/homebrew/bin/yabai -m space --focus "$target"
