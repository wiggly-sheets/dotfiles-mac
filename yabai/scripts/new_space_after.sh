#!/bin/dash
CURRENT_INDEX=$(yabai -m query --spaces --space | jq '.index')
yabai -m space --create
NEW_SPACE_INDEX=$(yabai -m query --spaces | jq 'max_by(.index).index')
TARGET_INDEX=$((CURRENT_INDEX + 1))
yabai -m space --focus "$NEW_SPACE_INDEX"
yabai -m space --move "$TARGET_INDEX"
yabai -m space --focus "$CURRENT_INDEX"
sketchybar --trigger space_change
sketchybar --trigger space_windows_change