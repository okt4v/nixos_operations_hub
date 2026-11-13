#!/usr/bin/env bash
# Keep the physical mic-mute LED in sync with the default source's mute state.
# ThinkPad E16 Gen 2 only: this AMD ACP mic has no hardware mute switch, so
# the kernel's audio-micmute LED trigger never fires on its own — this script
# is what actually drives the LED instead. No-op on any other machine/model.
led=/sys/class/leds/platform::micmute/brightness

[ -w "$led" ] || exit 0
[ "$(cat /sys/class/dmi/id/product_version 2>/dev/null)" = "ThinkPad E16 Gen 2" ] || exit 0

sync_led() {
  case "$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null)" in
    *yes*) echo 1 > "$led" ;;
    *) echo 0 > "$led" ;;
  esac
}

sync_led
pactl subscribe 2>/dev/null | while read -r line; do
  case "$line" in
    *"on source"*) sync_led ;;
  esac
done
