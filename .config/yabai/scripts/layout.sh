#!/usr/bin/env bash

current="$(yabai -m config external_bar)"

if [ "$current" = "all:0:0" ]; then
  # External display layout
  yabai -m config external_bar main:0:0
  sketchybar --bar y_offset=0
  sketchybar --bar margin=6
else
  # Internal display layout
  yabai -m config external_bar all:0:0
  sketchybar --bar y_offset=6
fi