# hack — switch the system to the `hack` profile (see modules/hack.nix), bring
# up the isolated lab network, work in ~/hkng. Asks for your password.
up() {
  on 1 kitty --working-directory "$HOME/hkng" sh -c "'sudo /nix/var/nix/profiles/system/specialisation/hack/bin/switch-to-configuration test; virsh -c qemu:///system net-start lab; exec \$SHELL'"
}
down() {
  swaymsg "exec kitty sh -c 'sudo /nix/var/nix/profiles/system/bin/switch-to-configuration test'" >/dev/null
}
