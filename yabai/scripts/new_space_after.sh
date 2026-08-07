#!/bin/dash
CURRENT_INDEX=$(/opt/homebrew/bin/yabai -m query --spaces --space | /opt/homebrew/bin/jq '.index')
/opt/homebrew/bin/yabai -m space --create
NEW_SPACE_INDEX=$(/opt/homebrew/bin/yabai -m query --spaces | /opt/homebrew/bin/jq 'max_by(.index).index')
TARGET_INDEX=$((CURRENT_INDEX + 1))
/opt/homebrew/bin/yabai -m space --focus "$NEW_SPACE_INDEX"
/opt/homebrew/bin/yabai -m space --move "$TARGET_INDEX"
/opt/homebrew/bin/yabai -m space --focus "$CURRENT_INDEX"
/opt/homebrew/bin/sketchybar --trigger space_change
/opt/homebrew/bin/sketchybar --trigger space_windows_change