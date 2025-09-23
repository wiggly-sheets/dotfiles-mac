#!/usr/bin/env zsh

# Check DND status
dnd_status=$(defaults read com.apple.controlcenter "NSStatusItem VisibleCC FocusModes" 2>/dev/null | awk '{gsub(/%/,""); print}')

if [ "$dnd_status" = "1" ]; then
  # DND is on: set moon.fill icon with magenta color
  sketchybar --set dnd label.color="0xffb39df3"
else
  # DND is off: set moon icon with grey color
  sketchybar --set dnd label.color="0xFF555555"
fi

