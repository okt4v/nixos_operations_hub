# Installer USB: `hub iso`, write result/iso/*.iso to a stick, boot it.
# It carries this flake at /etc/hub and accepts your SSH key as root, so a
# machine can be installed locally:
#   nmtui   (wifi)
#   sudo disko-install --flake /etc/hub#<host> --disk main /dev/<disk>
# or from another machine:  hub install <host> <ip>
{
  inputs,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";
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
    inputs.disko.packages.x86_64-linux.disko
    inputs.disko.packages.x86_64-linux.disko-install
  ];
}
