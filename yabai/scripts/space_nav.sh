#!/bin/bash
idx=$(/opt/homebrew/bin/yabai -m query --spaces --space | /opt/homebrew/bin/jq '.index')
total=$(/opt/homebrew/bin/yabai -m query --spaces | /opt/homebrew/bin/jq 'length')
zero=$((idx - 1))
row=$((zero / 4))
col=$((zero % 4))
row_start=$((row * 4 + 1))

case "$1" in
  left)
    if [ $col -eq 0 ]; then
      row_end=$((row_start + 3))
      [ $row_end -gt $total ] && row_end=$total
      /opt/homebrew/bin/yabai -m space --focus "$row_end"
    else
      /opt/homebrew/bin/yabai -m space --focus $((idx - 1))
    fi
    ;;
  right)
    if [ $col -eq 3 ]; then
      /opt/homebrew/bin/yabai -m space --focus "$row_start"
    else
      next=$((idx + 1))
      [ $next -gt $total ] && next=$row_start
      /opt/homebrew/bin/yabai -m space --focus "$next"
    fi
    ;;
  up|down)
    # Build the list of space indices that share this column,
    # in row order (skips rows where this column doesn't exist,
    # e.g. an incomplete last row).
    list=()
    i=$((col + 1))
    while [ $i -le $total ]; do
      list+=("$i")
      i=$((i + 4))
    done

    n=${#list[@]}
    pos=0
    for j in "${!list[@]}"; do
      if [ "${list[$j]}" -eq "$idx" ]; then
        pos=$j
        break
      fi
    done

    if [ "$1" = "up" ]; then
      new_pos=$(( (pos - 1 + n) % n ))
    else
      new_pos=$(( (pos + 1) % n ))
    fi

    /opt/homebrew/bin/yabai -m space --focus "${list[$new_pos]}"
    ;;
esac