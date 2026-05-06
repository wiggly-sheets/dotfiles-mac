#!/bin/bash

action=$(yabai -m config mouse_drop_action)

if [ "$action" = "swap" ]; then
yabai -m config mouse_drop_action stack
else
yabai -m config mouse_drop_action swap
fi