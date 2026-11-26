# Graphical session: swayfx, login, audio, bluetooth, fonts, sharing.
{ pkgs, ... }:

let
  shareTechMono = pkgs.runCommand "share-tech-mono" { } ''
    mkdir -p $out/share/fonts/truetype
    cp ${
      pkgs.fetchurl {
        url = "https://github.com/google/fonts/raw/main/ofl/sharetechmono/ShareTechMono-Regular.ttf";
        sha256 = "0xr6ffvbx8516rxb5h2767fzfgp079bkgxf0b7r9m0hlfkwb3slw";
      }
    } $out/share/fonts/truetype/ShareTechMono-Regular.ttf
  '';
  session = "${pkgs.zsh}/bin/zsh -lc 'exec sway'";
in
{
  fonts.packages = with pkgs; [
    shareTechMono
    inter
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    unscii
    nerd-fonts.departure-mono
  ];
  fonts.fontDir.enable = true;

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    package = pkgs.swayfx;
    extraPackages = with pkgs; [
      brightnessctl
      grim
      slurp
      swappy
      wf-recorder
      pulseaudio # pactl for the volume keys
      swayidle
      swaylock
      waybar
      mako
      libnotify
      fuzzel
      cliphist
      wl-clipboard
      hyprpicker
      jq
    ];
  };
  security.pam.services.swaylock = { };
  # Polkit prompt agent, started by sway so it inherits the session.
  environment.etc."sway/config.d/polkit.conf".text =
    "exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
  programs.dconf.enable = true;
  programs.ssh.startAgent = true; # KeePassXC adds and removes the keys

  # The disk passphrase already authenticated whoever booted the machine, so
  # the first session logs in directly. Logging out lands on tuigreet.
  # sway starts through the user's shell so it inherits the session variables
  # (PATH with the hub's bin/, TMUX_TMPDIR, ...) that keybindings rely on.
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = session;
        user = "oktav";
      };
      default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd '${session}'";
    };
  };

  services.power-profiles-daemon.enable = true;

  services.libinput.enable = true;

  services.printing.enable = true;

  # AirPlay receiver (`uxplay`) needs avahi to publish its services and these
  # fixed ports. Phone and laptop must be on the same LAN.
  services.avahi = {
    enable = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };
  programs.localsend.enable = true;
  networking.firewall = {
    allowedTCPPorts = [
      7000
      7001
      7100
    ];
    allowedUDPPorts = [
      6000
      6001
      6002
      7011
    ];
  };

  security.rtkit.enable = true; # realtime scheduling for audio
  services.upower.enable = true; # battery state for apps

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    # Bluetooth headphones win over every other output when connected.
    wireplumber.extraConfig."51-bluetooth-priority"."monitor.bluez.rules" = [
      {
        matches = [ { "node.name" = "~bluez_output.*"; } ];
        actions.update-props."priority.session" = 2000;
      }
    ];
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [
    kitty
    uxplay
    nautilus
    imv
    mpv
    zathura
    # TUI controllers opened from the bar
    btop
    bluetui
    impala
    wiremix
  ];
}
