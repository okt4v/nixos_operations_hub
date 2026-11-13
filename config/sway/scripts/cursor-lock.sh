#!/usr/bin/env bash
# Toggle confining the mouse cursor to the active monitor.
# Keyboard focus changes (e.g. $mod+1) still move the cursor to the target screen.
pid_file="${XDG_RUNTIME_DIR:-/tmp}/sway-cursor-lock.pid"

release() { swaymsg input type:pointer map_to_output '*' >/dev/null 2>&1; }

run_daemon() {
  echo $$ > "$pid_file"
  trap 'release; rm -f "$pid_file"' EXIT

  local applied=""
  apply() {
    local out cx cy
    out=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
    [[ -z "$out" || "$out" == "$applied" ]] && return
    swaymsg input type:pointer map_to_output "$out" >/dev/null
    if [[ -n "$applied" ]]; then
      read -r cx cy < <(swaymsg -t get_outputs | jq -r --arg o "$out" \
        '.[] | select(.name==$o) | "\(.rect.x + .rect.width/2 | floor) \(.rect.y + .rect.height/2 | floor)"')
      swaymsg seat - cursor set "$cx" "$cy" >/dev/null
    fi
    applied="$out"
  }

  apply
  swaymsg -t subscribe -m '["workspace","window"]' | while read -r _; do
    apply
  done
}

case "$1" in
  --daemon)
    run_daemon
    exit 0
    ;;
esac

if [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file" 2>/dev/null)" 2>/dev/null; then
  pid=$(cat "$pid_file")
  kill -- "-$pid" 2>/dev/null || kill "$pid" 2>/dev/null
  release
  rm -f "$pid_file"
  notify-send -t 1500 "Cursor unlocked" "Free to travel across monitors"
else
  rm -f "$pid_file"
  setsid -f "$0" --daemon >/dev/null 2>&1
  notify-send -t 1500 "Cursor locked" "Confined to the active monitor"
fi
