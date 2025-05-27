#!/bin/bash

# Function to get brightness for a specific display
get_brightness_percentage() {
    # Get brightness value and convert it to percentage
    local brightness=$(betterdisplaycli get --n="$1" --brightness=%)
    echo $(echo "$brightness * 100" | bc | awk '{printf "%d\n", $1}')
}

# Initialize variables for SketchyBar
one_display_icon="􀟛"    # Placeholder for icon when only one display is present
two_displays_icon="􂤓"  # Placeholder for icon when two displays are present
display_icon="$one_display_icon"           # Default to one display

# Get brightness percentage for the built-in display
main_brightness_percentage=$(get_brightness_percentage "built-in")

# Attempt to query brightness for the second display
second_brightness_percentage=""
second_display=$(betterdisplaycli get --n="sceptre" --brightness=% 2>/dev/null)

if [[ -n $second_display ]]; then
    # Calculate the brightness percentage for the second display
    second_brightness_percentage=$(echo "$second_display * 100" | bc | awk '{printf "%d\n", $1}')
    # Set the icon to indicate two displays
    display_icon="$two_displays_icon"
fi

# Prepare the label
if [[ -n $second_brightness_percentage ]]; then
    # Format label with both values
    label="${second_brightness_percentage}% & ${main_brightness_percentage}%"
else
    # Show only one display's brightness
    label="${main_brightness_percentage}%"
fi

# Update the SketchyBar with label and correct icon
# Replace 'your_item_name' with the actual item name in SketchyBar
sketchybar --set display label="$label" icon="$display_icon"

