#!/bin/bash

if pgrep -x "borders" >/dev/null; then
    # borders is running → stop it
    /opt/homebrew/bin/brew services stop borders
    /opt/homebrew/bin/yabai -m config top_padding 0
    /opt/homebrew/bin/yabai -m config bottom_padding 25
    /opt/homebrew/bin/yabai -m config right_padding 0
    /opt/homebrew/bin/yabai -m config left_padding 0
else
    # borders is not running → start it
    /opt/homebrew/bin/brew services start borders
    /opt/homebrew/bin/yabai -m config top_padding 0
    /opt/homebrew/bin/yabai -m config bottom_padding 25
    /opt/homebrew/bin/yabai -m config right_padding 2
    /opt/homebrew/bin/yabai -m config left_padding 2
fi