# Installer USB: `hub iso` (or bin/build-iso), write iso/*.iso to a stick, boot it.
# The installer (`hub-install`) starts on its own on the first console: it
# asks for wifi, host, disk and the disk passphrase. It carries this flake at
# /etc/hub and accepts your SSH key as root, so instead you can also run
# from another machine:  hub install <host> <ip>
{
  config,
  inputs,
  lib,
  modulesPath,
  pkgs,
  ...
}:

let
  # disko formats, nixos-install builds straight onto the target disk.
  # (disko-install would build the whole system into the stick's RAM first.)
  installer = pkgs.writeShellApplication {
    name = "hub-install";
    runtimeInputs = [
      pkgs.curl
      pkgs.git
      pkgs.util-linux
      pkgs.networkmanager
      pkgs.gptfdisk
      pkgs.openssh
      inputs.disko.packages.x86_64-linux.disko
    ];
    text = ''
      [ "$(id -u)" = 0 ] || exec sudo "$0" "$@"
      echo "ophub NixOS installer"

      until curl -fsI https://cache.nixos.org >/dev/null; do
        echo "No internet. Opening nmtui: activate a connection, then quit."
        read -rp "Enter to continue" _
        nmtui
      done

      # writable copy: the chosen disk and a new host are written into it; no
      # .git, or nix would ignore an uncommitted new host
      rm -rf /tmp/hub && cp -rL /etc/hub /tmp/hub && chmod -R u+w /tmp/hub && rm -rf /tmp/hub/.git

      echo; echo "Host to install:"
      mapfile -t hosts < <(find /tmp/hub/hosts -mindepth 1 -maxdepth 1 -type d ! -name iso -printf '%f\n' | sort)
      select host in "''${hosts[@]}" "new host (this machine)"; do [ -n "$host" ] && break; done

      new=
      if [ "$host" = "new host (this machine)" ]; then
        new=1 host=
        until [[ $host =~ ^[a-z][a-z0-9-]*$ ]] && [ ! -e "/tmp/hub/hosts/$host" ]; do
          read -rp "Name for this machine (lowercase, e.g. work-laptop): " host
        done
        mkdir "/tmp/hub/hosts/$host"
        cp /tmp/hub/hosts/dev-hub/features.nix "/tmp/hub/hosts/$host/"
        cat > "/tmp/hub/hosts/$host/default.nix" <<EOF
      # $host. The shared setup is modules/workstation.nix; this machine's quirks go here.
      {
        imports = [
          ./hardware.nix
          (import ../../modules/workstation.nix (import ./features.nix))
        ];

        hub.disk = "/dev/sda";
      }
      EOF
        {
          echo "# $host. Filesystems come from modules/disk.nix, not from here."
          nixos-generate-config --no-filesystems --show-hardware-config 2>/dev/null
        } > "/tmp/hub/hosts/$host/hardware.nix"
        echo "New host $host: the shared workstation setup, dev-hub's feature flags, this machine's hardware.nix."
      fi

      # every whole disk except the stick we booted from (no floppy, loop, cdrom, zram)
      boot=$(lsblk -no PKNAME "$(findmnt -no SOURCE /iso)" 2>/dev/null || true)
      echo; echo "Disk to install on:"
      mapfile -t disks < <(lsblk -dpno NAME,SIZE,MODEL -e 2,7,11 | grep -v -e "^/dev/zram" -e "^/dev/$boot " || true)
      select disk in "''${disks[@]}"; do [ -n "$disk" ] && break; done
      disk=''${disk%% *}

      echo; echo "How:"
      select how in "whole disk (erases everything on it)" "free space next to Windows (keeps it)"; do [ -n "$how" ] && break; done
      esp=
      if [[ $how == free* ]]; then
        esp=$(lsblk -lpno NAME,PARTTYPE "$disk" | awk '$2 == "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" { print $1; exit }')
        [ -n "$esp" ] || { echo "No EFI partition on $disk: is Windows installed there, in UEFI mode?"; exit 1; }
        [ ! -e /dev/disk/by-partlabel/nixos-crypt ] || { echo "A nixos-crypt partition exists already: delete the old Linux partitions first."; exit 1; }
        echo; echo "Keeps every partition on $disk and installs $host into its largest free space"
        echo "(shrink Windows first, in Windows' Disk Management)."
      else
        echo; echo "This ERASES everything on $disk and installs $host."
      fi
      read -rp "Type yes to continue: " ok
      [ "$ok" = yes ] || exit 1

      # the installed system mounts by partition label, so hub.disk only matters here
      f=/tmp/hub/hosts/$host/default.nix
      sed -i -e "s|hub.disk = \".*\";|hub.disk = \"$disk\";|" -e '/hub.dualBoot = /d' "$f"

      echo "Choose the disk passphrase when asked."
      if [ -n "$esp" ]; then
        sed -i "/hub.disk = /a\\  hub.dualBoot = { enable = true; esp = \"/dev/disk/by-uuid/$(blkid -s UUID -o value "$esp")\"; };" "$f"
        # XBOOTLDR for kernels (Windows' ESP is ~100M) + the encrypted rest
        sgdisk -n 0:0:+1G -t 0:ea00 -c 0:nixos-boot -n 0:0:0 -t 0:8309 -c 0:nixos-crypt "$disk"
        udevadm settle
        disko --mode format,mount --flake "/tmp/hub#$host"
        mkdir -p /mnt/efi && mount "$esp" /mnt/efi
      else
        disko --mode destroy,format,mount --yes-wipe-all-disks --flake "/tmp/hub#$host"
      fi
      # host key for remote unlock (modules/remote-unlock.nix); unused otherwise
      mkdir -p /mnt/var/lib/initrd-ssh
      ssh-keygen -q -t ed25519 -N "" -f /mnt/var/lib/initrd-ssh/ssh_host_ed25519_key
      nixos-install --flake "/tmp/hub#$host" --no-root-passwd --no-channel-copy

      # the repo at hub.dir, so dotfiles resolve and `hub switch` works at first login
      dir=$(nix eval --raw "/tmp/hub#nixosConfigurations.$host.config.hub.dir")
      mkdir -p "/mnt$dir"
      if git clone -q https://github.com/okt4v/nixos_operations_hub "/mnt$dir"; then
        cp -r "/tmp/hub/hosts/$host" "/mnt$dir/hosts/" # new host or changed disk: shows in git status
      else
        cp -r /tmp/hub/. "/mnt$dir/"
        echo "No git clone (offline?): $dir is a plain copy, connect it with git later."
      fi
      nixos-enter --root /mnt -c "chown -R oktav:users /home/oktav"
      umount -R /mnt # writes everything out: safe to power off from here

      echo; echo "Done. Remove the stick; first login password is changeme."
      [ -z "$new" ] || echo "Commit hosts/$host in $dir after first login."
      read -rp "Enter to reboot" _
      reboot
    '';
  };
in
{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";
  image.baseName = lib.mkForce "ophub-nixos-${config.system.nixos.release}-x86_64";
  isoImage.volumeID = "ophub-${config.system.nixos.release}";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  console.keyMap = "de-latin1-nodeadkeys";

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keyFiles = [ ../../secrets/oktav.pub ];
  users.users.nixos.openssh.authorizedKeys.keyFiles = [ ../../secrets/oktav.pub ];

  environment.etc."hub".source = ../..;
  environment.systemPackages = [
    pkgs.git
    installer
    inputs.disko.packages.x86_64-linux.disko
    inputs.disko.packages.x86_64-linux.disko-install
  ];

  # Start the installer on the first console; Ctrl+C drops to a shell.
  environment.loginShellInit = ''
    [ "$(tty)" = /dev/tty1 ] && [ "$USER" = nixos ] && hub-install
  '';
  services.getty.helpLine = lib.mkForce "ophub NixOS installer. Install: hub-install   wifi: nmtui";
}
