#!/bin/bash

split=$(yabai -m config split_type)

if [ "$split" = "horizontal" ]; then
yabai -m config split_type vertical
else
yabai -m config split_type horizontal
end
fi