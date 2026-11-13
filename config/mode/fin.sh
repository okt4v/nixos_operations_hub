# fin — markets and money: vault open, quotes, ledger.
up() {
  on 1 kitty sh -c "'vault open && watch -c -n 60 mkt'"
  on 2 kitty fava-open
}
down() {
  pkill -x fava || true
  vault close || true
}
