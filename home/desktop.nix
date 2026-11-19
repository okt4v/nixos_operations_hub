# Desktop session for the user. Everything under config/ is linked live into
# ~/.config: edit the file in the repo, reload the app, no rebuild.
{
  config,
  osConfig,
  pkgs,
  ...
}:

let
  live = path: config.lib.file.mkOutOfStoreSymlink "${osConfig.hub.dir}/${path}";
  pal = "${config.xdg.configHome}/pal/current";
in
{
  xdg.configFile = {
    "sway".source = live "config/sway";
    "waybar".source = live "config/waybar";
    "kanshi".source = live "config/kanshi";
    "eww".source = live "config/eww";
    "btop/btop.conf".source = live "config/btop/btop.conf";
    "fastfetch/logo.txt".source = live "config/fastfetch/logo.txt";
    "fastfetch/config.jsonc".source = config.lib.file.mkOutOfStoreSymlink "${pal}/fastfetch.jsonc";
    "mako/config".source = config.lib.file.mkOutOfStoreSymlink "${pal}/mako";

    "swappy/config".text = ''
      [Default]
      save_dir=$HOME/med/img/shot
      save_filename_format=%Y%m%d-%H%M%S.png
    '';

    "fuzzel/fuzzel.ini".text = ''
      include=${pal}/fuzzel.ini

      [main]
      font=Share Tech Mono:size=13
      terminal=kitty
      lines=12
      width=42
      prompt=>
      horizontal-pad=16
      vertical-pad=10
      inner-pad=4
      image-size-ratio=0.5
      match-mode=fzf

      [border]
      width=1
      radius=0
    '';
  };

  # Scripts are live too: `hub.dir/bin` is on PATH.
  home.sessionPath = [ "${osConfig.hub.dir}/bin" ];

  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    settings = {
      enable_audio_bell = false;
      visual_bell_duration = "0.0";
      allow_remote_control = true;
      font_family = "Share Tech Mono";
      font_size = "12.0";
    };
    keybindings = {
      "ctrl+minus" = "change_font_size current -2.0";
      "ctrl+equal" = "change_font_size current +2.0";
      "ctrl+plus" = "change_font_size current +2.0";
      "ctrl+0" = "change_font_size current 0";
      "shift+enter" = "send_text all \\x1b[13;2u";
    };
    extraConfig = "include ${pal}/kitty.conf";
  };

  # `theme` switches these two at runtime through gsettings.
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # Weekly: build the updated system in the background and report what would
  # change. Applying stays manual (`hub update`).
  systemd.user.services.hub-update = {
    Unit.Description = "Check for system updates";
    Service = {
      Type = "oneshot";
      Environment = "PATH=/run/wrappers/bin:/etc/profiles/per-user/oktav/bin:/run/current-system/sw/bin";
      ExecStart = "${osConfig.hub.dir}/bin/upd-check";
    };
  };
  systemd.user.timers.hub-update = {
    Unit.Description = "Weekly system update check";
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "2h";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 18;
  };

  home.packages = with pkgs; [
    glib # gsettings, used by `theme`
    libqalculate # qalc, used by `menu calc`
    bemoji # `menu emoji`
    kanshi
    eww # wallpaper dashboard, `widgets`
    playerctl # music widget
    nvd # package diff for `upd-check`
    nwg-displays # `hub mon`
    wl-mirror # `mode present`
    tesseract # `grab text`
    zbar # `grab qr`
  ];
}
