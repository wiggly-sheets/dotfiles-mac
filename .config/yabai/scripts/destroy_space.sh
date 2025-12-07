#!/usr/bin/env bash

# current space + display
cur=$(yabai -m query --spaces --space | jq -r ".index")
disp=$(yabai -m query --spaces --space | jq -r ".display")

# collect all spaces on this display
spaces=$(yabai -m query --spaces \
    | jq -r ".[] | select(.display == $disp) | .index" \
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
wins=$(yabai -m query --windows --space "$cur" | jq -r ".[].id")
for w in $wins; do
    yabai -m window "$w" --space "$target"
done

# destroy space
yabai -m space --destroy

# focus target (windows are already there)
yabai -m space --focus "$target"