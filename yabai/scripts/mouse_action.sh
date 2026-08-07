#!/bin/bash
[ "$(/opt/homebrew/bin/yabai -m config mouse_drop_action)" = "swap" ] && n=stack || n=swap
/opt/homebrew/bin/yabai -m config mouse_drop_action $n