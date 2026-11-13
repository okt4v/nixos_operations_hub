#!/usr/bin/env sh
# Toggle "disable trackpad while typing" (libinput dwt) for the touchpad
state=$(swaymsg -t get_inputs -r | jq -r '.[] | select(.type=="touchpad") | .libinput.dwt')

if [ "$state" = "enabled" ]; then
    swaymsg input type:touchpad dwt disable >/dev/null
else
    swaymsg input type:touchpad dwt enable >/dev/null
fi
