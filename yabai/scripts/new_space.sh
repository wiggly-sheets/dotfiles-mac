#!/bin/dash
# CONSOLIDATED REFERENCE - not active in skhdrc
# Replaces: new_space_after.sh, new_space_after_follow.sh, new_space_after_move.sh, new_space_after_move_focus.sh
# Args: focus move insert follow (all 0 or 1)
cid=$(/opt/homebrew/bin/yabai -m query --spaces --space | /opt/homebrew/bin/jq '.index')
/opt/homebrew/bin/yabai -m space --create
nid=$(/opt/homebrew/bin/yabai -m query --spaces | /opt/homebrew/bin/jq 'max_by(.index).index')
[ "$1" = "1" ] && /opt/homebrew/bin/yabai -m window --space "$nid"
[ "$2" = "1" ] && /opt/homebrew/bin/yabai -m space --focus "$nid"
[ "$3" = "1" ] && /opt/homebrew/bin/yabai -m space --move $((cid + 1))
[ "$4" = "1" ] && /opt/homebrew/bin/yabai -m space --focus "$cid"
/opt/homebrew/bin/sketchybar --trigger space_change
/opt/homebrew/bin/sketchybar --trigger space_windows_change