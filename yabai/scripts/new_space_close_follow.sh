#!/bin/dash

# Get index of the currently focused space
CURRENT_INDEX=$(yabai -m query --spaces --space | jq '.index')

# Create a new space
yabai -m space --create

# Get the index of the newly created space (highest index on this display)
NEW_SPACE_INDEX=$(yabai -m query --spaces | jq 'max_by(.index).index')

# Move the new space to one ahead of the current space
TARGET_INDEX=$((CURRENT_INDEX + 1))

yabai -m space --focus "$NEW_SPACE_INDEX"

# Move new space
yabai -m space --move "$TARGET_INDEX"

sketchybar --trigger space_change
sketchybar --trigger space_windows_change