# Installer USB: `hub iso` (or bin/build-iso), write iso/*.iso to a stick, boot it.
# The installer (`hub-install`, a TUI) starts on its own on the first console:
# keyboard, network, host, time zone, disk (whole, or next to Windows),
# passphrase, password, and a LUKS header backup to another stick. It carries this flake at
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
  # The installer TUI is hub-install.sh. disko formats, nixos-install builds
  # straight onto the target disk (disko-install would build the whole system
  # into the stick's RAM first).
  installer = pkgs.writeShellApplication {
    name = "hub-install";
    runtimeInputs = [
      pkgs.curl
      pkgs.git
      pkgs.util-linux
      pkgs.networkmanager
      pkgs.gptfdisk
      pkgs.openssh
      pkgs.dialog
      pkgs.jq
      pkgs.openssl
      pkgs.iproute2
      pkgs.ckbcomp
      pkgs.kbd
      pkgs.cryptsetup
      inputs.disko.packages.x86_64-linux.disko
    ];
    runtimeEnv.XKB_DIR = "${pkgs.xkeyboard_config}/etc/X11/xkb"; # for ckbcomp
    text = builtins.readFile ./hub-install.sh;
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
