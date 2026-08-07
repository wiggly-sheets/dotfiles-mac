#!/bin/dash
# Create a new space one index prior to the current space, then focus it.

cid=$(/opt/homebrew/bin/yabai -m query --spaces --space | /opt/homebrew/bin/jq '.index')
/opt/homebrew/bin/yabai -m space --create
nid=$(/opt/homebrew/bin/yabai -m query --spaces | /opt/homebrew/bin/jq 'max_by(.index).index')
/opt/homebrew/bin/yabai -m space "$nid" --move "$cid"
/opt/homebrew/bin/yabai -m space --focus "$cid"
/opt/homebrew/bin/sketchybar --trigger space_change
/opt/homebrew/bin/sketchybar --trigger space_windows_change
