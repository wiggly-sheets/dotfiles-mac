#!/bin/bash
win=$(yabai -m query --windows --window | jq -r '.id')
disp=$(yabai -m query --displays --display | jq -r '.index')
yabai -m space --create "$disp"
nid=$(yabai -m query --spaces --display "$disp" | jq '.[-1].index')
yabai -m window "$win" --space "$nid"
yabai -m space --focus "$nid"