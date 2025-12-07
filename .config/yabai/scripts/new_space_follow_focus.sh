# 1. current window
win=$(yabai -m query --windows --window | jq -r ".id")

# 2. current display
disp=$(yabai -m query --displays --display | jq -r ".index")

# 3. create space
yabai -m space --create "$disp"

# 4. re-query the last space (the one we just created)
new_space=$(yabai -m query --spaces --display "$disp" | jq '.[-1].index')

# 5. move window
yabai -m window "$win" --space "$new_space"

# 6. focus it
yabai -m space --focus "$new_space"