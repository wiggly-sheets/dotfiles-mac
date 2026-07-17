#!/bin/bash
[ "$(yabai -m config mouse_drop_action)" = "swap" ] && n=stack || n=swap
yabai -m config mouse_drop_action $n