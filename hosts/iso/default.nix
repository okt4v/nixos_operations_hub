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
      pkgs.util-linux
      pkgs.networkmanager
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

      echo; echo "Host to install:"
      mapfile -t hosts < <(find /etc/hub/hosts -mindepth 1 -maxdepth 1 -type d ! -name iso -printf '%f\n' | sort)
      select host in "''${hosts[@]}"; do [ -n "$host" ] && break; done

      # every whole disk except the stick we booted from (no floppy, loop, cdrom, zram)
      boot=$(lsblk -no PKNAME "$(findmnt -no SOURCE /iso)" 2>/dev/null || true)
      echo; echo "Disk to install on:"
      mapfile -t disks < <(lsblk -dpno NAME,SIZE,MODEL -e 2,7,11 | grep -v -e "^/dev/zram" -e "^/dev/$boot " || true)
      select disk in "''${disks[@]}"; do [ -n "$disk" ] && break; done
      disk=''${disk%% *}

      echo; echo "This ERASES everything on $disk and installs $host."
      read -rp "Type yes to continue: " ok
      [ "$ok" = yes ] || exit 1

      # writable copy with the chosen disk; the installed system mounts by
      # partition label, so hub.disk only matters here
      rm -rf /tmp/hub && cp -rL /etc/hub /tmp/hub && chmod -R u+w /tmp/hub
      sed -i "s|hub.disk = \".*\";|hub.disk = \"$disk\";|" "/tmp/hub/hosts/$host/default.nix"

      echo "Choose the disk passphrase when asked."
      disko --mode destroy,format,mount --yes-wipe-all-disks --flake "/tmp/hub#$host"
      nixos-install --flake "/tmp/hub#$host" --no-root-passwd --no-channel-copy

      echo; echo "Done. Remove the stick; first login password is changeme."
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
