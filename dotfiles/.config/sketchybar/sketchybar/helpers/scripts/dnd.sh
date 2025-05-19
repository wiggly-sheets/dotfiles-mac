#!/bin/bash

# Check DND status
dnd_status=$(defaults read com.apple.controlcenter "NSStatusItem Visible FocusModes" 2>/dev/null | awk '{gsub(/%/,""); print}')

if [ "$dnd_status" = "1" ]; then
  # DND is on: set moon.fill icon with magenta color
  sketchybar --set dnd label="􀆺"
else
  # DND is off: set moon icon with magenta color
  sketchybar --set dnd label="􀆹"
fi
