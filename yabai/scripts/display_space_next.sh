#!/bin/bash
yabai -m query --spaces --display | jq '
  if .[-1]."has-focus" then .[0].index else "next" end
' | xargs yabai -m space --focus