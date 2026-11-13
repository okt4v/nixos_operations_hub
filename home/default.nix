{ ... }:

{
  imports = [
    ./shell.nix
    ./desktop.nix
    ./palette.nix
    ./dev.nix
    ./apps.nix
    ./dirs.nix
    ./calendar.nix
    ./finance.nix
  ];

  home.username = "oktav";
  home.homeDirectory = "/home/oktav";
  home.stateVersion = "26.05";
}
