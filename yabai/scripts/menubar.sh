#!/bin/bash

# Get current menubar opacity
o=$(/opt/homebrew/bin/yabai -m config menubar_opacity)

# Check if opacity is >= 1
if awk "BEGIN{exit !($o>=1)}"; then
    # If opacity >= 1, hide menubar and show sketchybar
    /opt/homebrew/bin/yabai -m config menubar_opacity 0.0
    /opt/homebrew/bin/sketchybar --bar hidden=false y_offset=-50
    /opt/homebrew/bin/sketchybar --animate sin 12 --bar y_offset=5
else
    # If opacity < 1, show menubar and hide sketchybar
    /opt/homebrew/bin/sketchybar --bar hidden=true
    /opt/homebrew/bin/yabai -m config menubar_opacity 1.0
fi
