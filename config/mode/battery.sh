# battery — stretch a charge.
up() {
  pp power-saver
  brightnessctl -q -s set 30% || true # -s saves the old level
  bluetoothctl power off >/dev/null 2>&1 || true
}
down() {
  pp balanced
  brightnessctl -q -r || true # restore it
}
