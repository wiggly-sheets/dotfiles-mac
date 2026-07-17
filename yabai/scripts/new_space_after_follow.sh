#!/bin/dash
cid=$(yabai -m query --spaces --space | jq '.index')
yabai -m space --create
nid=$(yabai -m query --spaces | jq 'max_by(.index).index')
yabai -m space --focus "$nid"
yabai -m space --move $((cid + 1))
sketchybar --trigger space_change
sketchybar --trigger space_windows_change