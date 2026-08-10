#!/bin/sh
# ~/.config/yabai/borders-state.sh
wid="${1:?window id required}"
BORDERS="/opt/homebrew/bin/borders" # change if needed

window="$(yabai -m query --windows --window "$wid")"
space="$(printf '%s' "$window" | jq -r '.space')"
layout="$(yabai -m query --spaces --space "$space" | jq -r '.type')"

if [ "$(printf '%s' "$window" | jq -r '."is-floating"')" = true ]; then
  state=floating
elif [ "$(printf '%s' "$window" | jq -r '."stack-index"')" -gt 0 ] ||
     [ "$layout" = stack ]; then
  state=stack
elif [ "$layout" = bsp ]; then
  state=bsp
else
  state=none
fi

"$BORDERS" apply-to="$wid" state="$state"