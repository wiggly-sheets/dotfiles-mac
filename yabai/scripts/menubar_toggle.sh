#!/bin/bash

# Get current menubar opacity
o=$(yabai -m config menubar_opacity)

# Check if opacity is >= 1
if awk "BEGIN{exit !($o>=1)}"; then
    # If opacity >= 1, hide menubar and show sketchybar
    yabai -m config menubar_opacity 0.0
    sketchybar --bar hidden=false y_offset=-50
    sketchybar --animate sin 12 --bar y_offset=6
else
    # If opacity < 1, show menubar and hide sketchybar
    sketchybar --bar hidden=true
    yabai -m config menubar_opacity 1.0
fi
