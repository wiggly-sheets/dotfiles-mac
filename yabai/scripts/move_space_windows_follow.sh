#!/usr/bin/env bash
# Create a new space, move all windows from the current space into it,
# then focus the new space.

cid=$(/opt/homebrew/bin/yabai -m query --spaces --space | /opt/homebrew/bin/jq '.index')
disp=$(/opt/homebrew/bin/yabai -m query --spaces --space | /opt/homebrew/bin/jq '.display')
windows=$(/opt/homebrew/bin/yabai -m query --windows --space "$cid" | /opt/homebrew/bin/jq '.[].id')

/opt/homebrew/bin/yabai -m space --create "$disp"
nid=$(/opt/homebrew/bin/yabai -m query --spaces --display "$disp" | /opt/homebrew/bin/jq '.[-1].index')

for win in $windows; do
  /opt/homebrew/bin/yabai -m window "$win" --space "$nid"
done

/opt/homebrew/bin/yabai -m space --focus "$nid"
/opt/homebrew/bin/sketchybar --trigger space_change
/opt/homebrew/bin/sketchybar --trigger space_windows_change
