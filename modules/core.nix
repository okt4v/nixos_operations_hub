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

  # The host's feature flags (hosts/<host>/features.nix), for the few places
  # that need to ask instead of being a whole module.
  options.hub.features = lib.mkOption {
    type = lib.types.attrsOf lib.types.bool;
    default = { };
    description = "Feature flags of this host.";
  };

  # The host's optional apps (hosts/<host>/apps.nix, catalog in home/apps.nix).
  options.hub.apps = lib.mkOption {
    type = lib.types.attrsOf lib.types.bool;
    default = { };
    description = "Optional apps of this host: name = on/off.";
  };

  # Keyboard layout (xkb names), for the console, the disk passphrase at boot,
  # sway and X apps alike. The installer asks for it.
  options.hub.keyboard = {
    layout = lib.mkOption {
      type = lib.types.str;
      default = "de";
      description = "xkb layout: de, us, gb, fr, ch, ...";
    };
    variant = lib.mkOption {
      type = lib.types.str;
      default = "nodeadkeys";
      description = "xkb variant, \"\" for the plain layout.";
    };
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
    # console keymap so the disk passphrase is typed on hub.keyboard's layout.
    boot.initrd.systemd.enable = true;

    time.timeZone = lib.mkDefault "Europe/Vienna"; # the installer may set another per host
    services.xserver.xkb = {
      inherit (config.hub.keyboard) layout variant;
      options = "caps:escape";
    };
    # sway (config/sway/input.conf sets no layout) reads these
    environment.sessionVariables = {
      XKB_DEFAULT_LAYOUT = config.hub.keyboard.layout;
      XKB_DEFAULT_VARIANT = config.hub.keyboard.variant;
      XKB_DEFAULT_OPTIONS = "caps:escape";
    };
    console = {
      useXkbConfig = true; # the console keymap follows the xkb layout
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
