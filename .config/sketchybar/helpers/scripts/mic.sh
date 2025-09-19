#!/bin/bash

# Get input volume
volume=$(osascript -e 'set volInfo to input volume of (get volume settings)')

# Get mute status (returns true or false)
muted=$(osascript -e 'input muted of (get volume settings)')

# Function to check if a string is a valid integer
is_integer() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

if [ "$muted" = "true" ]; then
  # Mic is muted
  sketchybar --set mic icon="􀊳" label="Muted"
elif [ -z "$volume" ] || ! is_integer "$volume"; then
  # No valid input volume detected
  sketchybar --set mic icon="􀊳" label=""
elif [ "$volume" -eq 0 ]; then
  # Volume is zero but not muted
  sketchybar --set mic icon="􀊳" label="0%"
else
  # Mic is unmuted and volume > 0
  sketchybar --set mic icon="􀊱" label="${volume}%"
fi

