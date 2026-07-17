#!/bin/bash
# CONSOLIDATED REFERENCE - not active in skhdrc
# Replaces: new_space_focus.sh, new_space_window.sh, new_space_follow_focus.sh
# Args: move focus (both 0 or 1)
disp=$(yabai -m query --displays --display | jq -r '.index')
yabai -m space --create "$disp"
nid=$(yabai -m query --spaces --display "$disp" | jq '.[-1].index')
[ "$1" = "1" ] && { win=$(yabai -m query --windows --window | jq -r '.id'); yabai -m window "$win" --space "$nid"; }
[ "$2" = "1" ] && yabai -m space --focus "$nid"
sketchybar --trigger space_change
sketchybar --trigger space_windows_change