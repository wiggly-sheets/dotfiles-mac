#!/usr/bin/env bash
set -euo pipefail

while true; do
    # Find the first empty space, fresh query every iteration
    empty_space=$(yabai -m query --spaces | jq -r '
        [.[] | select((.windows | length) == 0)] | .[0].index // empty
    ')

    if [ -z "$empty_space" ]; then
        break
    fi

    echo "Deleting empty space $empty_space"
    if ! yabai -m space "$empty_space" --destroy; then
        break
    fi
done
