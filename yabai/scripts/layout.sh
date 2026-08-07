#!/usr/bin/env bash
if [ "$(/opt/homebrew/bin/yabai -m config external_bar)" = "all:0:0" ]; then
  /opt/homebrew/bin/yabai -m config external_bar main:0:0
  /opt/homebrew/bin/yabai -m config top_padding 10
  /opt/homebrew/bin/sketchybar --bar y_offset=5 padding_left=5 padding_right=5
else
  /opt/homebrew/bin/yabai -m config external_bar all:0:0
  /opt/homebrew/bin/yabai -m config top_padding 1
  /opt/homebrew/bin/sketchybar --bar y_offset=4 padding_left=0 padding_right=27


fi