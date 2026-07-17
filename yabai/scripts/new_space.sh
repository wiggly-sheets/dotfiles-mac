#!/bin/dash
# CONSOLIDATED REFERENCE - not active in skhdrc
# Replaces: new_space_after.sh, new_space_after_follow.sh, new_space_after_move.sh, new_space_after_move_focus.sh
# Args: focus move insert follow (all 0 or 1)
cid=$(yabai -m query --spaces --space | jq '.index')
yabai -m space --create
nid=$(yabai -m query --spaces | jq 'max_by(.index).index')
[ "$1" = "1" ] && yabai -m window --space "$nid"
[ "$2" = "1" ] && yabai -m space --focus "$nid"
[ "$3" = "1" ] && yabai -m space --move $((cid + 1))
[ "$4" = "1" ] && yabai -m space --focus "$cid"
sketchybar --trigger space_change
sketchybar --trigger space_windows_change