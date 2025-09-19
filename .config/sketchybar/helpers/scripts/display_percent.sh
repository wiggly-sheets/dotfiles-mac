#!/bin/bash

# Function to get brightness for a specific display
get_brightness_percentage() {
    # Get brightness value and convert it to percentage
    local brightness=$(betterdisplaycli get --n="$1" --brightness=%)
    echo $(echo "$brightness * 100" | bc | awk '{printf "%d\n", $1}')
}

# Define icons for different display configurations
main_only_icon="􀟛"       # Laptop icon
secondary_only_icon="􀙗" # External monitor icon
both_displays_icon="􂤓"  # Dual-screen icon
display_icon="$main_only_icon"  # Default to laptop icon

# Attempt to query brightness for both displays
main_brightness_percentage=""
second_brightness_percentage=""

# Check if built-in display is active
if betterdisplaycli get --n="built-in" --brightness=% >/dev/null 2>&1; then
    main_brightness_percentage=$(get_brightness_percentage "built-in")
fi

# Check if second display is active
if betterdisplaycli get --n="sceptre" --brightness=% >/dev/null 2>&1; then
    second_brightness_percentage=$(get_brightness_percentage "sceptre")
fi

# Prepare the label and icon based on which displays are active
if [[ -n "$main_brightness_percentage" && -n "$second_brightness_percentage" ]]; then
    # Both displays active
    label="${second_brightness_percentage}% & ${main_brightness_percentage}%"
    display_icon="$both_displays_icon"
elif [[ -n "$second_brightness_percentage" ]]; then
    # Only second display active
    label="${second_brightness_percentage}%"
    display_icon="$secondary_only_icon"
elif [[ -n "$main_brightness_percentage" ]]; then
    # Only main display active
    label="${main_brightness_percentage}%"
    display_icon="$main_only_icon"
else
    # No displays active (unlikely case)
    label="􀁟"
fi

# Update the SketchyBar with label and correct icon
sketchybar --set display label="$label" icon="$display_icon"

