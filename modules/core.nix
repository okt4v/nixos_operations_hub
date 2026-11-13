# Base for every host: nix itself, boot, locale, the user.
{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:

{
  imports = [ inputs.nix-index-database.nixosModules.nix-index ];

  # Where this repo lives on an installed machine. Live-linked dotfiles and
  # `hub` resolve against it, so it is the one place to change the location.
  options.hub.dir = lib.mkOption {
    type = lib.types.str;
    default = "/home/oktav/tec/nix";
    description = "Absolute path of the checked-out flake.";
  };

  config = {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      trusted-users = [ "@wheel" ];
    };
    nixpkgs.config.allowUnfree = true;

    # `nh os switch` shows a package diff before activating; clean replaces nix.gc.
    programs.nh = {
      enable = true;
      flake = config.hub.dir;
      clean = {
        enable = true;
        extraArgs = "--keep 10 --keep-since 14d";
      };
    };

    # `, tool` runs any package once without installing it.
    programs.nix-index-database.comma.enable = true;

    boot.loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    boot.loader.efi.canTouchEfiVariables = true;
    # systemd in the initrd: needed later for TPM unlock, and it carries the
    # console keymap so the disk passphrase is typed on the German layout.
    boot.initrd.systemd.enable = true;

    time.timeZone = "Europe/Vienna";
    console = {
      keyMap = "de-latin1-nodeadkeys";
      earlySetup = true;
    };

    zramSwap.enable = true;

    programs.zsh.enable = true;
    users.users.oktav = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups = [
        "wheel"
        "video"
        "render"
        "input"
      ];
      # ponytail: first-boot password, change with `passwd`. Replaced by a
      # sops-managed hash once secrets land (modules/sec).
      initialPassword = "changeme";
    };

    environment.systemPackages = with pkgs; [
      git
      neovim
      wget
      just
    ];

    # Never changes after the first install of a host.
    system.stateVersion = "26.05";
  };
}
