#!/bin/bash


opacity=$(yabai -m config active_window_opacity)

if [ "$opacity" = "1.0000" ]; then
yabai -m config active_window_opacity 0.95
else
yabai -m config active_window_opacity 1.0
fi