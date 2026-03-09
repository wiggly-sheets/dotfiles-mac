#!/bin/bash
brew services stop borders && killall borders
yabai -m config top_padding 0
yabai -m config bottom_padding 0
yabai -m config right_padding 0
yabai -m config left_padding 0