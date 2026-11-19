# Operations hub. `hub` opens a fuzzy menu of these; `hub <recipe>` runs one.
# Recipes run from the repo root, whatever directory you call them from.

host := `hostname`

[private]
default:
    @just --list

# build and activate this config
switch:
    nh os switch .

# activate until the next reboot only
test:
    nh os test .

# go back to the previous generation
rollback:
    sudo nixos-rebuild switch --rollback

# apply the update the weekly check prepared (branch `upd`), or update now
update:
    #!/usr/bin/env bash
    set -eu
    if git rev-parse -q --verify upd >/dev/null && ! git diff --quiet HEAD upd -- flake.lock; then
      git checkout upd -- flake.lock
    else
      nix flake update
    fi
    nh os switch . --ask
    : > "${XDG_STATE_HOME:-$HOME/.local/state}/hub/update"

# one-screen overview: mode, vpn, vault, projects, tasks, problems
status:
    @bin/status

# is this machine fully set up? lists every open one-time step
doctor:
    @bin/doctor

# network: wifi, address, VPN, tailnet
net:
    @bin/net

# build this config and show which packages would change, without activating
diff:
    nix build .#nixosConfigurations.{{ host }}.config.system.build.toplevel -o /tmp/hub-diff
    nvd diff /run/current-system /tmp/hub-diff

# list system generations
gens:
    nixos-rebuild list-generations | head -15

# delete old generations and unused store paths (keeps the last 5)
gc:
    nh clean all --keep 5

# search nixpkgs: hub search <words>
search *words:
    nh search {{ words }}

# open this repo in the editor
edit:
    @nvim .

# all key bindings (sway, tmux, keyboard layer, nvim, hub) in one searchable list
keys:
    @bin/keys

# wallpaper widgets: menu, or hub widgets list|on|off <name>|show|hide|pos top|bottom
widgets *args:
    @bin/widgets {{ args }}

# switch features of this host on/off: menu, or hub feature list|on|off <name>
feature *args:
    @bin/feature {{ args }}

# homelab services from config/homelab/services: which are up
probe:
    @bin/probe

# record a call and transcribe it into ~/doc/notes/meetings (run again to stop)
minutes:
    @bin/minutes

# change your password (also stores it for the feature freshRoot, where plain passwd is forgotten at reboot)
passwd:
    #!/usr/bin/env bash
    set -eu
    passwd
    dir=/etc; [ ! -d /persist/etc ] || dir=/persist/etc
    sudo sh -c "umask 077; getent shadow $USER | cut -d: -f2 > $dir/hub-password"

# weekly review note: time, done tasks, commits, open projects
review:
    @bin/review

# empty the capture inbox line by line: task, note, delete or keep
triage:
    @bin/triage

# a notification later: hub remind 25m "call back", hub remind 17:30 "leave"
remind *args:
    @bin/remind {{ args }}

# BIOS and device firmware updates (feature firmware)
firmware:
    fwupdmgr refresh --force
    fwupdmgr update

# what is using the disk: your home, interactively
disk:
    @ncdu -x ~

# what needs attention (failed units, disk, snapshots, backups, updates)
health:
    @bin/health

# evaluate everything and lint the scripts
check:
    nix flake check

# format nix files
fmt:
    find flake.nix hosts modules home templates -name "*.nix" -exec nixfmt {} +

# boot a host's config in a throwaway VM window (password: test): hub vm [host]
vm name=host:
    @bin/vm {{ name }}

# edit encrypted secrets (creates your age key on first use)
sec:
    @bin/sec

# open, close or show the encrypted vault ~/vlt: hub vault [open|close|status]
vault action="status":
    @bin/vault {{ action }}

# run every enabled backup now
bak:
    #!/usr/bin/env bash
    units=$(systemctl list-unit-files 'restic-backups-*.service' --no-legend | awk '{print $1}')
    [ -n "$units" ] || { echo "no backup target enabled (hub.backup.* in hosts/{{ host }}/default.nix)"; exit 1; }
    for u in $units; do echo "== $u"; sudo systemctl start "$u" && echo ok || journalctl -u "$u" -n 20 --no-pager; done

# prove restores work: random file from snapshot and from each backup
drill:
    @bin/drill

# monitors: arrange by drag and drop, or `hub mon save <name>` / `hub mon list`
mon *args:
    @bin/mon {{ args }}

# charge to 100% this once (the 80% cap returns at the next boot)
charge:
    echo 100 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold

# time tracked this week, by mode and project
report:
    timew summary :week

# turn a PDF or scan back into LaTeX source: hub untex <file.pdf>
untex file:
    @cd "{{ invocation_directory() }}" && {{ justfile_directory() }}/bin/untex "{{ file }}"

# accounting dashboard (opens the vault, starts fava)
fava:
    @bin/fava-open

# quotes for the watchlist, or `hub mkt hist <symbol>` for parquet history
mkt *args:
    @bin/mkt {{ args }}

# disposable lab VMs: hub lab up|down|reset <name>, hub lab list
lab *args:
    @bin/lab {{ args }}

# run a coding agent in a jailed worktree of the current repo: hub agent <name> [command]
agent name *cmd:
    @cd "{{ invocation_directory() }}" && {{ justfile_directory() }}/bin/agent "{{ name }}" {{ cmd }}

# project services from devenv.nix in the current directory: hub svc up|down
svc action="up":
    @cd "{{ invocation_directory() }}" && {{ justfile_directory() }}/bin/svc {{ action }}

# build the installer USB image into iso/ (bin/build-iso, works on non-NixOS too)
iso:
    @bin/build-iso

# write the installer ISO to a USB stick (only USB disks are offered)
flash:
    @bin/flash

# install a test host with the real installer in a VM and boot it (~10 min, KVM)
test-install:
    @bin/test-install

# install a host onto a machine booted from the hub ISO: hub install <host> <ip>
install name ip:
    nix run github:nix-community/nixos-anywhere -- --flake .#{{ name }} root@{{ ip }}

# rebuild a remote host from here: hub deploy <host>
deploy name:
    nixos-rebuild switch --flake .#{{ name }} --target-host {{ name }} --sudo

# create a project from a template: hub new [template] [name]
new tpl="" name="":
    @bin/new "{{ tpl }}" "{{ name }}"
