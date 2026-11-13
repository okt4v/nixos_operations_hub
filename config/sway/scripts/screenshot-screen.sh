#!/usr/bin/env bash
# Screenshot the focused output, edit in swappy, then copy to clipboard
output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
grim -o "$output" - | swappy -f - -o - | wl-copy
