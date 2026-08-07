#!/bin/dash
# Create a new space one index prior to the current space, move the
# currently focused window into it, but leave focus on the current space.

cid=$(/opt/homebrew/bin/yabai -m query --spaces --space | /opt/homebrew/bin/jq '.index')
wid=$(/opt/homebrew/bin/yabai -m query --windows --window | /opt/homebrew/bin/jq '.id')
/opt/homebrew/bin/yabai -m space --create
nid=$(/opt/homebrew/bin/yabai -m query --spaces | /opt/homebrew/bin/jq 'max_by(.index).index')
/opt/homebrew/bin/yabai -m space "$nid" --move "$cid"
/opt/homebrew/bin/yabai -m window "$wid" --space "$cid"
/opt/homebrew/bin/sketchybar --trigger space_change
/opt/homebrew/bin/sketchybar --trigger space_windows_change
