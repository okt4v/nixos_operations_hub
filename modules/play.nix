# Games: Steam, Roblox (Sober), wine.
{ inputs, pkgs, ... }:

{
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  programs.steam.enable = true;

  services.flatpak = {
    enable = true;
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    packages = [
      {
        appId = "org.vinegarhq.Sober"; # Roblox
        origin = "flathub";
      }
    ];
  };

  # Aseprite ignores fontconfig and scans /usr/share/fonts, which doesn't
  # exist on NixOS. Point it at the real fonts.
  systemd.tmpfiles.rules = [
    "L+ /usr/share/fonts - - - - /run/current-system/sw/share/X11/fonts"
  ];

  # godot, aseprite, blender: optional apps (hosts/<host>/apps.nix)
  environment.systemPackages = [ pkgs.wine ];
}
