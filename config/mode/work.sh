# work — separate browser profile, work identity (git picks it up by folder:
# ~/dev/work, ~/doc/work), personal noise off.
up() {
  dnd on
  pp balanced
  # TODO(you): connect the work VPN here once you know which kind it is
  on 2 zen-beta -P work
  on 1 kitty --working-directory "$HOME/dev/work"
}
down() {
  dnd off
  pkill -f 'zen.*-P work' || true
}
