#!/usr/bin/env bash
yabai -m space --create
nid=$(yabai -m query --spaces --display | jq '.[-1].index')
windows=$(yabai -m query --windows --space | jq '.[].id')
for win in $windows; do
  yabai -m window "$win" --space "$nid"
done
yabai -m space --focus "$nid"