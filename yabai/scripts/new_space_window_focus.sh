#!/bin/bash
win=$(/opt/homebrew/bin/yabai -m query --windows --window | /opt/homebrew/bin/jq -r '.id')
disp=$(/opt/homebrew/bin/yabai -m query --displays --display | /opt/homebrew/bin/jq -r '.index')
/opt/homebrew/bin/yabai -m space --create "$disp"
nid=$(/opt/homebrew/bin/yabai -m query --spaces --display "$disp" | /opt/homebrew/bin/jq '.[-1].index')
/opt/homebrew/bin/yabai -m window "$win" --space "$nid"
/opt/homebrew/bin/yabai -m space --focus "$nid"