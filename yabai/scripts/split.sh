#!/bin/bash

split=$(/opt/homebrew/bin/yabai -m config split_type)

if [ "$split" = "horizontal" ]; then
/opt/homebrew/bin/yabai -m config split_type vertical
else
/opt/homebrew/bin/yabai -m config split_type horizontal
fi