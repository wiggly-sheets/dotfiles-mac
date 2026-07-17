#!/bin/bash
yabai -m query --spaces --display | jq '
  if .[0]."has-focus" then .[-1].index else "prev" end
' | xargs yabai -m space --focus