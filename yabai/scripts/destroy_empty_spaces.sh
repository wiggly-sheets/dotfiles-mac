#!/usr/bin/env bash
set -euo pipefail

is_effectively_empty() {
    local space_id="$1"
    local window_count

    window_count=$(
        /opt/homebrew/bin/yabai -m query --windows --space "$space_id" | /opt/homebrew/bin/jq -r '
            [ .[]
              | select(
                    ((.app // "") != "Atoll")
              )
            ] | length
        '
    )

    [ "$window_count" -eq 0 ]
}

while true; do
    # Find the first effectively empty space, fresh query every iteration.
    # Finder can keep a space "non-empty" even when there are no user windows,
    # so ignore Finder-only spaces.
    empty_space=""
    while IFS= read -r space_id; do
        if is_effectively_empty "$space_id"; then
            empty_space="$space_id"
            break
        fi
    done < <(/opt/homebrew/bin/yabai -m query --spaces | /opt/homebrew/bin/jq -r '.[].index')

    if [ -z "$empty_space" ]; then
        break
    fi

    echo "Deleting empty space $empty_space"
    /opt/homebrew/bin/yabai -m space "$empty_space" --destroy || true
done
