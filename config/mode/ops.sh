# ops — homelab: pick a host, deploy recipes at hand.
up() {
  pp balanced
  on 1 kitty hp
  on 2 kitty --working-directory "$HOME/tec/nix"
}
