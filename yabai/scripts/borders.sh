#!/bin/bash

if pgrep -x "borders" >/dev/null; then
    # borders is running → stop it
    brew services stop borders
    yabai -m config top_padding 0
    yabai -m config bottom_padding 25
    yabai -m config right_padding 0
    yabai -m config left_padding 0
else
    # borders is not running → start it
    brew services start borders
    yabai -m config top_padding 0
    yabai -m config bottom_padding 25
    yabai -m config right_padding 2
    yabai -m config left_padding 2
fi