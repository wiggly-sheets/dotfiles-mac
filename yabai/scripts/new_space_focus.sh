#!/bin/bash
disp=$(yabai -m query --displays --display | jq -r '.index')
yabai -m space --create "$disp"
nid=$(yabai -m query --spaces --display "$disp" | jq '.[-1].index')
yabai -m space --focus "$nid"