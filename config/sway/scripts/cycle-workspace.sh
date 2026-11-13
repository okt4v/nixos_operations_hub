#!/usr/bin/env bash
# Cycle to next/prev workspace on the currently focused output only
direction=${1:-next}

current_output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
current_ws=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .num')

mapfile -t ws_nums < <(swaymsg -t get_workspaces \
  | jq -r --arg out "$current_output" \
    '[.[] | select(.output == $out)] | sort_by(.num) | .[].num')

count=${#ws_nums[@]}
current_idx=0
for i in "${!ws_nums[@]}"; do
  if [[ "${ws_nums[$i]}" == "$current_ws" ]]; then
    current_idx=$i
    break
  fi
done

if [[ "$direction" == "next" ]]; then
  target_idx=$(( (current_idx + 1) % count ))
else
  target_idx=$(( (current_idx - 1 + count) % count ))
fi

swaymsg workspace number "${ws_nums[$target_idx]}"
