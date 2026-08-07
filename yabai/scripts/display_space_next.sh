#!/bin/bash
/opt/homebrew/bin/yabai -m query --spaces --display | /opt/homebrew/bin/jq '
  if .[-1]."has-focus" then .[0].index else "next" end
' | xargs /opt/homebrew/bin/yabai -m space --focus