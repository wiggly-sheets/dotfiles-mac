#!/bin/bash
# CONSOLIDATED REFERENCE - not active in skhdrc
# Replaces: new_space_focus.sh, new_space_window.sh, new_space_follow_focus.sh
# Args: move focus (both 0 or 1)
disp=$(/opt/homebrew/bin/yabai -m query --displays --display | /opt/homebrew/bin/jq -r '.index')
/opt/homebrew/bin/yabai -m space --create "$disp"
nid=$(/opt/homebrew/bin/yabai -m query --spaces --display "$disp" | /opt/homebrew/bin/jq '.[-1].index')
[ "$1" = "1" ] && { win=$(/opt/homebrew/bin/yabai -m query --windows --window | /opt/homebrew/bin/jq -r '.id'); /opt/homebrew/bin/yabai -m window "$win" --space "$nid"; }
[ "$2" = "1" ] && /opt/homebrew/bin/yabai -m space --focus "$nid"
/opt/homebrew/bin/sketchybar --trigger space_change
/opt/homebrew/bin/sketchybar --trigger space_windows_change