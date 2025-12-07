# 1. capture current window
win=$(yabai -m query --windows --window | jq -r ".id")

# 2. capture current display
disp=$(yabai -m query --displays --display | jq -r ".index")

# 3. create a new space on that display
yabai -m space --create "$disp"

# 4. re-query the last space (the one just created)
new_space=$(yabai -m query --spaces --display "$disp" | jq '.[-1].index')

# 5. move the window to it
yabai -m window "$win" --space "$new_space"