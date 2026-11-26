#!/usr/bin/env bash
# hub-install — the ophub NixOS installer. Starts by itself on the ISO's first
# console (a TUI; "Shell" leaves it, `hub-install` starts it again).
#
# Asks for: keyboard layout, network, host (or a new one, with its features), time zone, disk,
# how much of it (whole disk / free space next to Windows or another system /
# replace one partition / reinstall over a previous ophub), disk passphrase,
# login password. Then shows a summary, and installs only after you agree.
#
# Without questions (bin/test-install uses this):
#   hub-install --host H --disk /dev/X --layout whole|free|ophub|/dev/<part> \
#     --passphrase-file F [--password P] [--timezone Z] [--keyboard L[:V]] \
#     [--size GiB] [--header-backup FILE] --yes
# Built into the ISO by hosts/iso/default.nix (shellchecked there).
set -euo pipefail
[ "$(id -u)" = 0 ] || exec sudo "$0" "$@"

title="ophub NixOS installer"
dopts=(--backtitle "$title" --cr-wrap --no-collapse) # texts keep their newlines and spacing
log=/tmp/hub-install.log
hub=/tmp/hub
esp_type=c12a7328-f81f-11d2-ba4b-00a0c93ec93b
msr_type=e3c9e316-0b5c-4db8-817d-f92df00215ae
default_tz=Europe/Vienna
host='' disk='' layout='' pass='' upass='' tz='' size='' kb='' hdr='' new='' tui=1

while [ $# -gt 0 ]; do
  case $1 in
    --host) host=$2 ;;
    --disk) disk=$2 ;;
    --layout) layout=$2 ;;
    --passphrase-file) pass=$(cat "$2") ;;
    --password) upass=$2 ;;
    --timezone) tz=$2 ;;
    --keyboard) kb=$2 ;;          # xkb layout[:variant], e.g. us or de:nodeadkeys
    --header-backup) hdr=$2 ;;    # file to write the LUKS header backup to
    --size) size=$2 ;;
    --yes) tui='' && shift && continue ;;
    *) echo "hub-install: unknown option $1 (see the top of hub-install.sh)" >&2; exit 1 ;;
  esac
  shift 2
done

# --- dialog helpers -----------------------------------------------------------
# ask <dialog args>: the answer on stdout, the screen on the terminal
ask() { dialog "${dopts[@]}" --output-fd 3 "$@" 3>&1 1>/dev/tty; }
# d <dialog args>: prints the answer. Cancel/Esc offers to quit, else asks again.
d() {
  local out
  if out=$(ask "$@"); then printf '%s' "$out"; return; fi
  # runs inside $(...): end the whole installer, not just this subshell
  dialog "${dopts[@]}" --yesno "Quit the installer?\n\nNothing has been changed yet. hub-install starts it again." 8 60 >/dev/tty && { clear >/dev/tty; kill -USR1 "$$"; exit 1; }
  d "$@"
}
msg() { if [ -n "$tui" ]; then dialog "${dopts[@]}" --msgbox "$1" 0 0; else echo "$1"; fi; }
die() { echo "[$(date +%T)] STOPPED: $1" >>"$log"; msg "$1"; handled=1; exit 1; }

note() { echo "[$(date +%T)] $*" >>"$log"; } # a line in the log
# run <title> <cmd...>: output goes to the log and, live, into a box
step=''
run() {
  step=$1
  note "=== $1"
  if [ -n "$tui" ]; then
    "${@:2}" 2>&1 | tee -a "$log" | dialog "${dopts[@]}" --title " $1 " --progressbox 22 90
  else
    echo "=== $1"; "${@:2}" 2>&1 | tee -a "$log"
  fi
}
# on any error: say which command failed, show the log, offer to keep it
failed() {
  local rc=$1 line=$2 cmd=$3
  handled=1
  note "FAILED (exit $rc)${step:+ in the step \"$step\"}${line:+, hub-install line $line: $cmd}"
  [ -n "$tui" ] || { { tail -n 20 "$log"; echo "FAILED, full log: $log"; } >&"$( { true >&4; } 2>/dev/null && echo 4 || echo 2)"; exit "$rc"; }
  local saved=''
  while true; do
    case $(ask --title " Installation failed " --no-cancel --menu \
"$(tail -n 12 "$log" | cut -c1-110)

The full log is $log. It lives in memory: save it before you reboot.${saved:+
Saved to: $saved}" 0 0 3 \
      view "read the whole log" save "save it to a USB stick" shell "leave the installer") in
      view) dialog "${dopts[@]}" --title " $log " --textbox "$log" 0 0 >/dev/tty || true ;;
      save)
        if usb_mount; then
          saved=/run/hub-usb/hub-install-$(date +%Y%m%d-%H%M).log
          cp "$log" "$saved" && sync && umount /run/hub-usb && saved+=" (on the stick)"
        fi ;;
      *) clear >/dev/tty; exit "$rc" ;;
    esac
  done
}
# usb_mount: pick a partition on a USB stick (not the installer's) and mount it
# at /run/hub-usb; fails when there is none or the user cancels
usb_mount() {
  local boot items name bytes fs type pk dev p
  boot=$(lsblk -no PKNAME "$(findmnt -no SOURCE /iso)" 2>/dev/null || true)
  while true; do
    items=()
    # a filesystem on a USB disk: on a partition, or on the whole stick
    while read -r name bytes fs type pk; do
      dev=$name; [ "$type" != part ] || dev=$pk
      [ "${dev##*/}" != "$boot" ] && [ "$(lsblk -dno TRAN "$dev")" = usb ] || continue
      items+=("$name" "$fs $(numfmt --to=iec "$bytes")")
    done < <(lsblk -lpnbo NAME,SIZE,FSTYPE,TYPE,PKNAME | awk '$3 ~ /^(vfat|exfat|ext4|ntfs)$/ && ($4 == "disk" || $4 == "part")')
    if [ ${#items[@]} -eq 0 ]; then
      dialog "${dopts[@]}" --yes-label "Look again" --no-label Cancel --yesno "Plug in a USB stick (FAT, exFAT, NTFS or ext4)." 7 60 >/dev/tty || return 1
      continue
    fi
    p=$(ask --menu "Save it on:" 0 50 0 "${items[@]}") || return 1
    mkdir -p /run/hub-usb && mount "$p" /run/hub-usb && return 0
  done
}

# --- disk helpers ---------------------------------------------------------------
gib() { echo $(( $1 * $(blockdev --getss "$disk") / 1073741824 )); } # sectors -> GiB
largest_free() { # "start end" of the disk's largest free block, in sectors
  local s e
  s=$(sgdisk -F "$disk" 2>/dev/null | tail -n1) e=$(sgdisk -E "$disk" 2>/dev/null | tail -n1)
  [[ $s =~ ^[0-9]+$ && $e =~ ^[0-9]+$ && $e -gt $s ]] && echo "$s $e" || echo "0 0"
}
part_range() { # part_range <partition>: its "start end" in the disk's sectors
  local n=${1##*/} f
  f=$(( $(blockdev --getss "$disk") / 512 )) # sysfs counts 512-byte units
  echo "$(( $(cat "/sys/class/block/$n/start") / f )) $(( ($(cat "/sys/class/block/$n/start") + $(cat "/sys/class/block/$n/size")) / f - 1 ))"
}
part_num() { cat "/sys/class/block/${1##*/}/partition"; }
parts() { # parts <disk>: one line per partition: name parttype fstype bytes partlabel label
  lsblk -Jpbo NAME,TYPE,PARTTYPE,FSTYPE,SIZE,PARTLABEL,LABEL "$1" | jq -r '.blockdevices[0].children[]? | select(.type == "part")
    | [.name, (.parttype // "-"), (.fstype // "-"), .size, (.partlabel // "-" | gsub("\\s"; "_")), (.label // "")] | join(" ")'
}
describe() { # describe <disk>: a short summary of what is on it
  local out="" name pt fs bytes _
  while read -r name pt fs bytes _; do
    [ "$pt" != "$esp_type" ] || fs=EFI
    [ "$pt" != "$msr_type" ] || continue
    [ "$fs" != - ] || fs=unformatted
    out+="$fs $(numfmt --to=iec "$bytes"), "
  done < <(parts "$1")
  out=${out%, }
  echo "${out:-empty}"
}

# An error ends the installer with the failure screen: the ERR trap for
# commands at the top level, the EXIT trap for those inside functions (where
# set -e exits without ERR). A deliberate stop sets `handled` first.
handled=''
trap 'failed $? $LINENO "$BASH_COMMAND"' ERR
trap 'rc=$?; [ "$rc" = 0 ] || [ -n "$handled" ] || failed "$rc" "" ""' EXIT
trap 'handled=1; exit 0' USR1 # "Quit the installer?" answered yes
: >"$log"
note "ophub NixOS installer, on NixOS $(nixos-version 2>/dev/null)"

# --- 1. keyboard -------------------------------------------------------------------
# first, so everything typed from here on (wifi password, names, passphrase) is
# typed on the right layout; also the console, the passphrase at boot and the
# desktop of the installed system (hub.keyboard)
if [ -z "$kb" ] && [ -n "$tui" ]; then
  kb=$(d --title " Keyboard " --default-item de:nodeadkeys --menu "Keyboard layout. It applies right away, and the disk passphrase is typed the same way at boot." 0 60 0 \
    de:nodeadkeys German us "English (US)" gb "English (UK)" ch Swiss fr French es Spanish it Italian \
    pt Portuguese nl Dutch se Swedish no Norwegian dk Danish "fi" Finnish pl Polish cz Czech hu Hungarian)
fi
kb=${kb:-de:nodeadkeys}
[[ $kb =~ ^[a-z]+(:[a-z_]*)?$ ]] || die "Keyboard layout $kb: use e.g. us or de:nodeadkeys."
kbl=${kb%%:*} kbv=''
[[ $kb != *:* ]] || kbv=${kb#*:}
ckbcomp -I"$XKB_DIR" -rules evdev -layout "$kbl" -variant "$kbv" 2>/dev/null | loadkeys -q 2>/dev/null || true

# --- 2. welcome, network ----------------------------------------------------------
if [ -n "$tui" ]; then
  ip=$(ip -4 -o addr show scope global | awk '{ sub("/.*", "", $4); print $4; exit }' || true)
  dialog "${dopts[@]}" --yes-label Install --no-label Shell --yesno \
"Welcome to ophub NixOS.

This installs ophub NixOS onto a disk of this computer: the whole disk, or only free space or one partition next to Windows or another system. Nothing is changed before the summary at the end.

Shell: leave the installer (start it again with: hub-install)
${ip:+From another machine: hub install <host> $ip}" 15 76 || { clear; exit 0; }
fi

until curl -fsI --max-time 10 https://cache.nixos.org >/dev/null 2>&1; do
  [ -n "$tui" ] || die "No internet."
  case $(d --menu "No internet connection. A cable works by itself; for wifi:" 11 60 3 \
    wifi "connect to a wifi network (nmtui)" retry "check again" shell "leave the installer") in
    wifi) nmtui || true ;;
    shell) clear; exit 0 ;;
  esac
done

# writable copy: the chosen disk and a new host are written into it; no .git,
# or nix would ignore an uncommitted new host
rm -rf "$hub" && cp -rL /etc/hub "$hub" && chmod -R u+w "$hub" && rm -rf "$hub/.git"

# --- 3. host ------------------------------------------------------------------------
if [ -z "$host" ]; then
  items=()
  while read -r h; do items+=("$h" "$(sed -n '1s/^# *//p' "$hub/hosts/$h/default.nix" | cut -c1-50)"); done \
    < <(find "$hub/hosts" -mindepth 1 -maxdepth 1 -type d ! -name iso -printf '%f\n' | sort)
  host=$(d --title " Host " --menu "Which configuration to install. A new host gets the shared desktop, the features you pick, and this machine's hardware." $(( ${#items[@]} / 2 + 10 )) 76 $(( ${#items[@]} / 2 + 1 )) \
    "${items[@]}" "+new" "a new host for this machine")
fi
if [ "$host" = "+new" ]; then
  new=1 host=
  until [[ $host =~ ^[a-z][a-z0-9-]*$ ]] && [ ! -e "$hub/hosts/$host" ]; do
    host=$(d --title " New host " --inputbox "Name for this machine: lowercase letters, digits, dashes (e.g. work-laptop)." 9 60 "$host")
  done
  mkdir "$hub/hosts/$host"
  cp "$hub/hosts/dev-hub/features.nix" "$hub/hosts/$host/"
  # features: every `name = true|false; # what` line of dev-hub's features.nix
  items=()
  # the kanata layer (config/kanata) is written for the German layout: off elsewhere
  while read -r n v c; do
    [ "$n" != keyboard ] || [ "$kbl" = de ] || v=false
    items+=("$n" "$c" "$([ "$v" = true ] && echo on || echo off)")
  done \
    < <(sed -nE 's/^  ([a-zA-Z]+) = (true|false); # (.*)/\1 \2 \3/p' "$hub/hosts/$host/features.nix")
  note="Space switches a feature. Change them later with: hub feature"
  [ "$kbl" = de ] || note+="\nkeyboard starts off: its layer is made for the German layout."
  on=$(d --title " Features " --separate-output --checklist "$note" 0 90 0 "${items[@]}")
  sed -i -E 's/^(  [a-zA-Z]+ = )true;/\1false;/' "$hub/hosts/$host/features.nix"
  for n in $on; do sed -i -E "s/^(  $n = )false;/\1true;/" "$hub/hosts/$host/features.nix"; done
  # apps: dev-hub's list, all off; the user picks
  sed -E 's/^(  [a-zA-Z]+ = )true;/\1false;/' "$hub/hosts/dev-hub/apps.nix" >"$hub/hosts/$host/apps.nix"
  items=()
  while read -r n c; do items+=("$n" "$c" off); done \
    < <(sed -nE 's/^  ([a-zA-Z]+) = (true|false); # (.*)/\1 \3/p' "$hub/hosts/$host/apps.nix")
  on=$(d --title " Apps " --separate-output --checklist "Apps to install. Add or remove any later with: hub apps" 0 90 0 "${items[@]}")
  for n in $on; do sed -i -E "s/^(  $n = )false;/\1true;/" "$hub/hosts/$host/apps.nix"; done
  cat >"$hub/hosts/$host/default.nix" <<EOF
# $host. The shared setup is modules/workstation.nix; this machine's quirks go here.
{
  imports = [
    ./hardware.nix
    (import ../../modules/workstation.nix (import ./features.nix))
  ];

  hub.disk = "/dev/sda";
  hub.apps = import ./apps.nix;
}
EOF
  {
    echo "# $host. Filesystems come from modules/disk.nix, not from here."
    nixos-generate-config --no-filesystems --show-hardware-config 2>/dev/null
  } >"$hub/hosts/$host/hardware.nix"
fi
[ -f "$hub/hosts/$host/default.nix" ] || die "No host $host in hosts/."

# --- 4. time zone ---------------------------------------------------------------------
[ -n "$tui" ] || tz=${tz:-$default_tz}
while [[ ! $tz =~ ^[A-Za-z0-9_+/-]+$ ]] || [ ! -f "/etc/zoneinfo/$tz" ]; do
  [ -n "$tui" ] || die "Unknown time zone $tz."
  tz=$(d --title " Time zone " --inputbox "Region/City, e.g. Europe/Vienna, America/New_York, Asia/Tokyo." 9 60 "${tz:-$default_tz}")
done

# --- 5. disk ------------------------------------------------------------------------
if [ -z "$disk" ]; then
  boot=$(lsblk -no PKNAME "$(findmnt -no SOURCE /iso)" 2>/dev/null || true) # the stick
  items=()
  while read -r name bytes model; do
    [[ $name == /dev/zram* || $name == "/dev/$boot" ]] && continue
    items+=("$name" "$(numfmt --to=iec "$bytes") ${model:-disk}: $(describe "$name")")
  done < <(lsblk -dpnbo NAME,SIZE,MODEL -e 2,7,11)
  [ ${#items[@]} -gt 0 ] || die "No disk found to install on."
  disk=$(d --title " Disk " --menu "Install onto which disk? After the size: what is on it now." 0 90 $(( ${#items[@]} / 2 )) "${items[@]}")
fi
[ -b "$disk" ] || die "$disk is not a disk."

# --- 6. how much of it ----------------------------------------------------------------
esp=$(parts "$disk" | awk -v t="$esp_type" '$2 == t { print $1; exit }')
read -r fstart fend < <(largest_free)
free_gib=$([ "$fend" -gt 0 ] && gib $(( fend - fstart + 1 )) || echo 0)
old=$(parts "$disk" | awk '$5 == "nixos-boot" || $5 == "nixos-crypt" { print $1 }' | xargs)
[ -n "$tui" ] || size=${size:-$free_gib}
if [ -z "$layout" ]; then
  items=(whole "Erase the WHOLE disk and use all of it")
  if [ -n "$esp" ]; then
    [ "$free_gib" -lt 30 ] || items+=(free "Use the free space (${free_gib} GiB), keep every partition")
    [ "$(echo "$old" | wc -w)" != 2 ] || items+=(ophub "Reinstall over the previous ophub NixOS, keep the rest")
    while read -r name pt fs bytes _ label; do
      [ "$pt" = "$esp_type" ] || [ "$pt" = "$msr_type" ] || [[ " $old " == *" $name "* ]] && continue
      [ "$fs" != - ] || fs=unformatted
      items+=("$name" "Replace this partition only: $fs $(numfmt --to=iec "$bytes") $label")
    done < <(parts "$disk")
    note="Windows (or another system) stays and appears in the boot menu."
    [ "$free_gib" -ge 30 ] || note+="\nNo free space of 30 GiB or more: shrink Windows first (Disk Management, Shrink Volume)."
  else
    note="Sharing the disk needs an EFI partition on it (Windows installed in UEFI mode)."
  fi
  def=whole # the free space, if there is enough, is the safe default
  [ "${items[2]:-}" != free ] || def=free
  layout=$(d --title " How " --default-item "$def" --menu "$note" 0 90 $(( ${#items[@]} / 2 )) "${items[@]}")
fi

dual='' replace=() start='' end=''
case $layout in
  whole) ;;
  free)
    [ "$free_gib" -ge 30 ] || die "Only ${free_gib} GiB free on $disk; ophub NixOS needs 30 GiB or more."
    while [[ ! $size =~ ^[0-9]+$ ]] || [ "$size" -lt 30 ] || [ "$size" -gt "$free_gib" ]; do
      [ -n "$tui" ] || die "--size must be 30..$free_gib GiB."
      size=$(d --title " Size " --inputbox "GiB to use for ophub NixOS (30 to $free_gib). Whatever you leave stays free." 9 70 "${size:-$free_gib}")
    done
    start=$fstart end=$(( fstart + size * 1073741824 / $(blockdev --getss "$disk") - 1 ))
    [ "$end" -le "$fend" ] || end=$fend
    dual=1 ;;
  ophub) read -ra replace <<<"$old"; dual=1 ;;
  /dev/*) replace=("$layout") dual=1 ;;
  *) die "Unknown layout $layout." ;;
esac
if [ -n "$dual" ]; then
  [ -n "$esp" ] || die "No EFI partition on $disk: is Windows installed there, in UEFI mode?"
  if [ ${#replace[@]} -gt 0 ]; then
    for p in "${replace[@]}"; do [ "$(lsblk -no PKNAME "$p")" = "${disk##*/}" ] || die "$p is not on $disk."; done
    read -r start _ < <(part_range "${replace[0]}")
    read -r _ end < <(part_range "${replace[-1]}")
  fi
  # the installed system finds its partitions by label: there may be only one of each
  for l in nixos-boot nixos-crypt; do
    for p in $(lsblk -lpno NAME,PARTLABEL | awk -v l=$l '$2 == l { print $1 }'); do
      [[ " ${replace[*]} " == *" $p "* ]] || die "A partition labelled $l exists already ($p). Pick \"Reinstall over the previous ophub NixOS\" or delete it first."
    done
  done
fi

# --- 7. passphrase, password ------------------------------------------------------------
while [ -z "$pass" ]; do
  a=$(d --title " Disk passphrase " --insecure --passwordbox "Encrypts the disk; asked at every boot. Keep it safe: without it the data is gone." 10 70)
  b=$(d --title " Disk passphrase " --insecure --passwordbox "Once more:" 8 70)
  if [ -z "$a" ]; then msg "The passphrase cannot be empty."; elif [ "$a" != "$b" ]; then msg "They do not match."; else pass=$a; fi
done
while [ -n "$tui" ] && [ -z "$upass" ]; do
  a=$(d --title " Login password " --insecure --passwordbox "Password for the user oktav (also for sudo). Empty: changeme" 10 70)
  b=$(d --title " Login password " --insecure --passwordbox "Once more:" 8 70)
  if [ "$a" = "$b" ]; then upass=${a:-changeme}; else msg "They do not match."; fi
done
upass=${upass:-changeme}

# --- 8. summary --------------------------------------------------------------------------
case $layout in
  whole) what="ERASES ALL OF $disk ($(describe "$disk"))" ;;
  free) what="Uses $size GiB of the free space on $disk; every partition stays" ;;
  *) what="ERASES ${replace[*]} on $disk; every other partition stays" ;;
esac
warn=
[[ $(describe "$disk") != *BitLocker* ]] || warn="\n\nWindows uses BitLocker: have its recovery key at hand, Windows may ask for it once."
[ -z "$dual" ] || warn+="\n\nTurn off Windows Fast Startup, or Windows may leave its partitions half-written."
shared="1G boot partition + encrypted btrfs; the EFI partition stays, mounted at /efi"
[ -n "$dual" ] || shared="EFI partition + encrypted btrfs"
summary="Host:       $host${new:+ (new)}
Time zone:  $tz
Keyboard:   $kb
Disk:       $what
Layout:     $shared
User:       oktav$warn"
if [ -n "$tui" ]; then
  if [ "$layout" = free ]; then
    dialog "${dopts[@]}" --title " Ready " --defaultno --yes-label Install --yesno "$summary" 0 0 || { clear; exit 0; }
  else
    [ "$(d --title " Ready " --inputbox "$summary\n\nThis erases data. Type yes to install:" 0 0)" = yes ] || { clear; exit 0; }
  fi
fi

# --- 9. install --------------------------------------------------------------------------
# from here on every error message goes to the log (the screens use /dev/tty)
exec 4>&2 2>>"$log" # 4: the real stderr, for the no-questions mode
note "--- choices"
echo "${summary//\\n/ }" >>"$log"
note "--- disks before"
lsblk -o NAME,SIZE,TYPE,FSTYPE,PARTLABEL,LABEL,MOUNTPOINT >>"$log"
# the host file records the disk and how it is shared; it is copied into the
# installed repo, so `git diff` there shows what the installer chose
f=$hub/hosts/$host/default.nix
sed -i -e "s|hub.disk = \".*\";|hub.disk = \"$disk\";|" -e '/hub.dualBoot = /d' -e '/time.timeZone = /d' -e '/hub.keyboard = /d' "$f"
[ "$tz" = "$default_tz" ] || sed -i "/hub.disk = /a\\  time.timeZone = \"$tz\";" "$f"
[ "$kb" = de:nodeadkeys ] || sed -i "/hub.disk = /a\\  hub.keyboard = { layout = \"$kbl\"; variant = \"$kbv\"; };" "$f"

disko_fmt() { printf '%s\n%s\n' "$pass" "$pass" | disko "$@"; } # passphrase on stdin, asked twice
if [ -n "$dual" ]; then
  sed -i "/hub.disk = /a\\  hub.dualBoot = { enable = true; esp = \"/dev/disk/by-uuid/$(blkid -s UUID -o value "$esp")\"; };" "$f"
  ss=$(blockdev --getss "$disk")
  bend=$(( start + 1073741824 / ss - 1 ))
  args=()
  for p in "${replace[@]}"; do umount "$p" 2>/dev/null || true; args+=(-d "$(part_num "$p")"); done
  # 1G XBOOTLDR for the kernels (Windows' EFI partition is ~100M) + the encrypted rest
  run "Partitioning" sgdisk "${args[@]}" -n "0:$start:$bend" -t 0:ea00 -c 0:nixos-boot \
    -n "0:$(( bend + 1 )):$end" -t 0:8309 -c 0:nixos-crypt "$disk"
  partx -u "$disk" 2>/dev/null || true
  udevadm settle
  for l in nixos-boot nixos-crypt; do wipefs -aq "/dev/disk/by-partlabel/$l"; done
  run "Formatting" disko_fmt --mode format,mount --flake "$hub#$host"
  mkdir -p /mnt/efi && mount "$esp" /mnt/efi
else
  run "Formatting" disko_fmt --mode destroy,format,mount --yes-wipe-all-disks --flake "$hub#$host"
fi
# host key for remote unlock (modules/remote-unlock.nix); unused otherwise
mkdir -p /mnt/var/lib/initrd-ssh
ssh-keygen -q -t ed25519 -N "" -f /mnt/var/lib/initrd-ssh/ssh_host_ed25519_key
run "Installing (downloads and builds; takes a while)" nixos-install --flake "$hub#$host" --no-root-passwd --no-channel-copy

# the repo at hub.dir, so dotfiles resolve and `hub switch` works at first login
dir=$(nix eval --raw "$hub#nixosConfigurations.$host.config.hub.dir")
mkdir -p "/mnt$dir"
if run "Getting the repo" git clone -q https://github.com/okt4v/nixos_operations_hub "/mnt$dir"; then
  cp -r "$hub/hosts/$host" "/mnt$dir/hosts/" # new host, disk, time zone: shows in git status
else
  cp -r "$hub/." "/mnt$dir/"
  echo "No git clone (offline?): $dir is a plain copy, connect it with git later." >>"$log"
fi
nixos-enter --root /mnt -c "chown -R oktav:users /home/oktav" >>"$log" 2>&1
printf 'oktav:%s\n' "$upass" | nixos-enter --root /mnt -c chpasswd >>"$log" 2>&1
# freshRoot (modules/fresh-root.nix) reads the password from /persist
[ ! -d /mnt/persist ] || { mkdir -p /mnt/persist/etc && openssl passwd -6 -stdin <<<"$upass" >/mnt/persist/etc/hub-password; }

# a copy of the LUKS header, kept off this disk: if the header is ever damaged,
# the passphrase alone cannot open the disk any more
luksdev=$(cryptsetup status crypt | awk '$1 == "device:" { print $2 }')
if [ -z "$hdr" ] && [ -n "$tui" ] &&
  dialog "${dopts[@]}" --title " Header backup " --yes-label Save --no-label Skip --yesno \
"Save a backup of the disk's encryption header to another USB stick?

If the header at the start of the encrypted partition is ever damaged, the passphrase alone cannot open the disk. With this file it can:
  cryptsetup luksHeaderRestore <partition> --header-backup-file <file>
It is useless without the passphrase. Plug in the stick now." 15 76; then
  ! usb_mount || hdr=/run/hub-usb/ophub-$host-luks-header.img
fi
if [ -n "$hdr" ]; then
  rm -f "$hdr"
  cryptsetup luksHeaderBackup "$luksdev" --header-backup-file "$hdr"
  echo "LUKS header of $luksdev saved to $hdr" >>"$log"
  ! mountpoint -q /run/hub-usb || umount /run/hub-usb
fi
note "--- done; disks after"
lsblk -o NAME,SIZE,TYPE,FSTYPE,PARTLABEL,LABEL,MOUNTPOINT >>"$log"
install -m 600 "$log" /mnt/var/log/hub-install.log
umount -R /mnt # writes everything out: safe to power off from here

done_msg="Installed. Remove the stick and reboot.

At boot: the disk passphrase. Then log in as oktav.
The repo is at $dir$([ -z "$new" ] || echo "; commit hosts/$host there").
The install log is /var/log/hub-install.log."
[ "$upass" != changeme ] || done_msg+="\nThe password is changeme: change it with passwd."
if [ -n "$tui" ]; then
  dialog "${dopts[@]}" --title " Done " --yes-label Reboot --no-label Shell --yesno "$done_msg" 0 0 && reboot
  clear
else
  echo "$done_msg"
fi
