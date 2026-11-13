#!/usr/bin/env sh
# Pick a power profile via fuzzel and persist it across reboots
choice=$(powerprofilesctl list \
    | grep -E "^[* ]+[a-z]" \
    | sed "s/[* ]//g; s/://" \
    | fuzzel --dmenu --no-exit-on-keyboard-focus-loss --prompt="profile> ")

[ -n "$choice" ] || exit 0
powerprofilesctl set "$choice" || exit 1

mkdir -p "$HOME/.cache"
printf '%s\n' "$choice" > "$HOME/.cache/power-profile"
