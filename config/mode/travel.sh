# travel — untrusted networks: VPN forced, no local sharing, save power,
# lock quickly.
up() {
  sudo net-trust untrusted
  pp power-saver
  pkill -x uxplay || true
  pkill -x localsend_app || true
}
down() {
  sudo net-trust auto
  pp balanced
}
