#!/usr/bin/env bash

current="$(yabai -m config external_bar)"

if [ "$current" = "all:0:0" ]; then
  # External display layout
  yabai -m config external_bar main:0:0
  yabai -m config window_gap 5
  yabai -m config top_padding 2
  yabai -m config bottom_padding 1
  yabai -m config left_padding 1
  yabai -m config right_padding 1

  sketchybar --bar y_offset=-5
else
  # Internal display layout
  yabai -m config external_bar all:0:0
  yabai -m config window_gap 5
  yabai -m config top_padding 1
  yabai -m config bottom_padding 1
  yabai -m config left_padding 1
  yabai -m config right_padding 1

  sketchybar --bar y_offset=0
fi