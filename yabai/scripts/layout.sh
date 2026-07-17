#!/usr/bin/env bash
if [ "$(yabai -m config external_bar)" = "all:0:0" ]; then
  yabai -m config external_bar main:0:0
  yabai -m config top_padding 10
  m=10
else
  yabai -m config external_bar all:0:0
  yabai -m config top_padding 0
  m=8
fi
sketchybar --bar y_offset=5 margin=$m --default padding_left=5 padding_right=5
killall PingPlace 2>/dev/null; open -a PingPlace
