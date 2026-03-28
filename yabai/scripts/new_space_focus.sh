# 1. get current display
disp=$(yabai -m query --displays --display | jq -r ".index")

# 2. create the space
yabai -m space --create "$disp"

# 3. re-query the newly created space (always the last one)
new_space=$(yabai -m query --spaces --display "$disp" | jq '.[-1].index')

# 4. focus it
yabai -m space --focus "$new_space"