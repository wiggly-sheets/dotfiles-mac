#!/usr/bin/env bash

current="$(yabai -m config external_bar)"

if [ "$current" = "all:0:0" ]; then
  # External display layout
  yabai -m config external_bar main:0:0
  yabai -m config top_padding 10
  sketchybar --bar y_offset=5
  sketchybar --bar margin=10
  sketchybar --default padding_left=5 padding_right=5
  killall PingPlace && open -a PingPlace

else
  # Internal display layout
  yabai -m config external_bar all:0:0
  yabai -m config top_padding 0
  sketchybar --bar y_offset=5
  sketchybar --bar margin=8
  sketchybar --default padding_left=5 padding_right=5
  killall PingPLace && open -a PingPlace
fi
