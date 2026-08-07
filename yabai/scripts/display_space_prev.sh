#!/bin/bash
/opt/homebrew/bin/yabai -m query --spaces --display | /opt/homebrew/bin/jq '
  if .[0]."has-focus" then .[-1].index else "prev" end
' | xargs /opt/homebrew/bin/yabai -m space --focus