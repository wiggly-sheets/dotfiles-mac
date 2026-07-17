#!/bin/bash
idx=$(yabai -m query --spaces --space | jq '.index')
total=$(yabai -m query --spaces | jq '.length')
zero=$((idx - 1))
row=$((zero / 4))
col=$((zero % 4))
row_start=$((row * 4 + 1))

case "$1" in
  left)
    if [ $col -eq 0 ]; then
      row_end=$((row_start + 3))
      [ $row_end -gt $total ] && row_end=$total
      yabai -m space --focus "$row_end"
    else
      yabai -m space --focus $((idx - 1))
    fi
    ;;
  right)
    if [ $col -eq 3 ]; then
      yabai -m space --focus "$row_start"
    else
      next=$((idx + 1))
      [ $next -gt $total ] && next=$row_start
      yabai -m space --focus "$next"
    fi
    ;;
  up)
    if [ $row -eq 0 ]; then
      last_row=$(( (total - 1) / 4 ))
      last_row_start=$(( last_row * 4 + 1 ))
      last_row_end=$(( last_row_start + 3 ))
      [ $last_row_end -gt $total ] && last_row_end=$total
      target=$(( last_row_start + col ))
      [ $target -gt $last_row_end ] && target=$last_row_end
      yabai -m space --focus "$target"
    else
      yabai -m space --focus $((idx - 4))
    fi
    ;;
  down)
    next=$((idx + 4))
    if [ $next -gt $total ]; then
      first_row_end=4
      [ $first_row_end -gt $total ] && first_row_end=$total
      target=$(( 1 + col ))
      [ $target -gt $first_row_end ] && target=$first_row_end
      yabai -m space --focus "$target"
    else
      yabai -m space --focus "$next"
    fi
    ;;
esac