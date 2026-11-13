# present — projector or screen share: nothing pops up, nothing sleeps.
up() {
  dnd on
  pkill -USR1 waybar || true # hide the bar
  systemd-inhibit --what=idle --who=mode --why=present sleep infinity &
  echo $! >"${XDG_RUNTIME_DIR:-/tmp}/mode-present.pid"
  # mirror the laptop panel onto whatever else is connected
  ext=$(swaymsg -t get_outputs | jq -r '[.[] | select(.active and .name != "eDP-1")][0].name // empty')
  [ -z "$ext" ] || { command -v wl-mirror >/dev/null && swaymsg "exec wl-mirror --fullscreen-output $ext eDP-1" >/dev/null; }
}
down() {
  dnd off
  pkill -USR1 waybar || true
  pkill -x wl-mirror || true
  kill "$(cat "${XDG_RUNTIME_DIR:-/tmp}/mode-present.pid" 2>/dev/null)" 2>/dev/null || true
}
