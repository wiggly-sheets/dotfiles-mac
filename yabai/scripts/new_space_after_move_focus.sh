#!/bin/dash
cid=$(/opt/homebrew/bin/yabai -m query --spaces --space | /opt/homebrew/bin/jq '.index')
/opt/homebrew/bin/yabai -m space --create
nid=$(/opt/homebrew/bin/yabai -m query --spaces | /opt/homebrew/bin/jq 'max_by(.index).index')
/opt/homebrew/bin/yabai -m window --space "$nid"
/opt/homebrew/bin/yabai -m space --focus "$nid"
/opt/homebrew/bin/yabai -m space --move $((cid + 1))
/opt/homebrew/bin/sketchybar --trigger space_change
/opt/homebrew/bin/sketchybar --trigger space_windows_change