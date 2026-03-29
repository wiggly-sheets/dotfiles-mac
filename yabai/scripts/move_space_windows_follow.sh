#!/usr/bin/env bash

# create new space on current display
yabai -m space --create

# get index of the newly created space (last space on display)
new_space=$(yabai -m query --spaces --display | jq '.[-1].index')

# get all window ids on current space
windows=$(yabai -m query --windows --space | jq '.[].id')

# move each window
for win in $windows; do
  yabai -m window "$win" --space "$new_space"
done

yabai -m space --focus "$new_space"

