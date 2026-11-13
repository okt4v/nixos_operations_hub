#!/usr/bin/env bash
# Development helper: build this checkout and boot it in a VM window.
#   ./vm.sh          this machine's config
#   ./vm.sh <host>   another host from hosts/
# Works on a machine that doesn't run this config yet. Inside the VM: login
# is automatic, the password is `test`, Super+Shift+Escape returns your own
# shortcuts to the host. Details in bin/vm.
exec "$(dirname "$(readlink -f "$0")")/bin/vm" "$@"
