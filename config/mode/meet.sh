# meet — calls: nothing pops up, the screen stays on.
up() {
  dnd on
  systemd-inhibit --what=idle --who=mode --why=meeting sleep infinity &
  echo $! >"${XDG_RUNTIME_DIR:-/tmp}/mode-meet.pid"
}
down() {
  dnd off
  kill "$(cat "${XDG_RUNTIME_DIR:-/tmp}/mode-meet.pid" 2>/dev/null)" 2>/dev/null || true
}
