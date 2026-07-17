#!/bin/bash
[ "$(yabai -m config active_window_opacity)" = "1.0000" ] && { o=0.95; n=.70; } || { o=1.0; n=.80; }
yabai -m config active_window_opacity $o
yabai -m config normal_window_opacity $n