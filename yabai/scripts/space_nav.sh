#!/bin/bash
# Usage: space_nav.sh [left|right|up|down]

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

row_width=4
direction="$1"

idx=$($YABAI -m query --spaces --space | $JQ '.index')
total=$($YABAI -m query --spaces | $JQ 'length')

col=$(( (idx - 1) % row_width ))
row_start=$((idx - col))

case "$direction" in
  right)
    if [ "$col" -eq $((row_width - 1)) ]; then
      target=$row_start
    else
      target=$((idx + 1))
      if [ "$target" -gt "$total" ]; then
        target=$row_start
      fi
    fi
    ;;

  left)
    if [ "$col" -eq 0 ]; then
      target=$((row_start + row_width - 1))
      if [ "$target" -gt "$total" ]; then
        target=$total
      fi
    else
      target=$((idx - 1))
    fi
    ;;

  down)
    target=$((idx + row_width))
    if [ "$target" -gt "$total" ]; then
      target=$((col + 1))
    fi
    ;;

  up)
    target=$((idx - row_width))
    if [ "$target" -lt 1 ]; then
      last_row=$(( (total - 1) / row_width ))
      target=$((last_row * row_width + col + 1))
      if [ "$target" -gt "$total" ]; then
        target=$((target - row_width))
      fi
    fi
    ;;
esac

$YABAI -m space --focus "$target"