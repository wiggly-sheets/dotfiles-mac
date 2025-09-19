#!/bin/bash

# Get lowpowermode status (0 or 1)
mode=$(pmset -g | grep lowpowermode | grep -o '[01]')

if [ "$mode" = "1" ]; then
  # Low power mode enabled: green lightning bolt
  sketchybar --set lowpowermode label.color="0xff9ed072"
else
  # Low power mode disabled: orange lightning bolt
  sketchybar --set lowpowermode label.color="0xfff39660"
fi

