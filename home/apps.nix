# GUI applications.
{
  inputs,
  config,
  osConfig,
  lib,
  pkgs,
  unstable,
  ...
}:

let
  zen = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
  amo = name: {
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/${name}/latest.xpi";
    installation_mode = "normal_installed";
  };
  # Feature `browser`: these apply to every profile, the work one included.
  # ponytail: policies only. Profiles are still created in the browser
  # (`zen-beta -P`); the flake's home-manager module can declare those too.
  policies = {
    DisableTelemetry = true;
    DisableFirefoxStudies = true;
    DisablePocket = true;
    DontCheckDefaultBrowser = true;
    # KeePassXC holds the passwords
    OfferToSaveLogins = false;
    PasswordManagerEnabled = false;
    ExtensionSettings = {
      "uBlock0@raymondhill.net" = amo "ublock-origin";
      "keepassxc-browser@keepassxc.org" = amo "keepassxc-browser";
    };
  };
  # Optional apps: on/off per host in hosts/<host>/apps.nix (`hub apps`).
  # New app: a line here and a line in every host's apps.nix.
  catalog = with pkgs; {
    thunderbird = thunderbird;
    spotify = spotify;
    mullvad = mullvad-vpn; # GUI; the daemon is in modules/network.nix
    obsidian = obsidian;
    anki = anki-bin;
    zotero = zotero;
    onlyoffice = onlyoffice-desktopeditors;
    libreoffice = libreoffice;
    vscode = unstable.vscode; # ponytail: fails to build on 26.05 (patchPhase); back to stable once fixed
    gimp = gimp;
    inkscape = inkscape; # also `fig`
    krita = krita;
    darktable = darktable;
    audacity = audacity;
    kdenlive = kdePackages.kdenlive;
    qalculate = qalculate-gtk;
    openscreen = callPackage ../pkgs/openscreen.nix { };
    godot = godot;
    aseprite = aseprite;
    # Blender's Wayland backend misbehaves under sway; run it through XWayland.
    blender = symlinkJoin {
      name = "blender";
      paths = [ blender ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = "wrapProgram $out/bin/blender --unset WAYLAND_DISPLAY";
    };
    freecad = freecad;
    vlc = vlc;
    calibre = calibre;
    signal = signal-desktop;
    element = element-desktop;
    telegram = telegram-desktop;
    discord = vesktop; # Discord with Wayland screen sharing
  };
  wanted = osConfig.hub.apps;
  unknown = lib.attrNames (lib.removeAttrs wanted (lib.attrNames catalog));
in
{
  assertions = [
    {
      assertion = unknown == [ ];
      message = "hosts/<host>/apps.nix names apps that home/apps.nix does not know: ${toString unknown}";
    }
  ];

  home.packages = lib.attrValues (lib.filterAttrs (n: _: wanted.${n} or false) catalog) ++ [
    (
      if osConfig.hub.features.browser or false then
        # the flake's own wrapper; its `.override { extraPolicies }` is lost
        # when the browser is wrapped, so the policies go to the wrapper here
        import "${inputs.zen-browser}/wrap-zen.nix" pkgs.wrapFirefox zen.unwrapped {
          icon = "zen-browser";
          extraPolicies = policies;
        }
      else
        zen
    )
    pkgs.keepassxc # always: the key hub (SSH agent, secret service)
  ];

  # KeePassXC is the key hub: its database serves SSH keys to the agent and
  # passwords to applications (secret service). The app rewrites its own
  # settings file, so it is only seeded once and stays writable. Per-key and
  # per-entry setup is done in the app, see docs/INSTALL.md.
  home.activation.keepassxcSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ini="${config.xdg.configHome}/keepassxc/keepassxc.ini"
    if [ ! -e "$ini" ] || [ -L "$ini" ]; then
      run rm -f "$ini"
      run mkdir -p "$(dirname "$ini")"
      run cp ${pkgs.writeText "keepassxc.ini" ''
        [GUI]
        ShowTrayIcon=true
        MinimizeOnClose=true

        [SSHAgent]
        Enabled=true

        [FdoSecrets]
        Enabled=true
      ''} "$ini"
      run chmod 600 "$ini"
    fi
  '';

  # Feature `mail`: aerc's config, linked live like the rest of config/.
  xdg.configFile."aerc" = lib.mkIf (osConfig.hub.features.mail or false) {
    source = config.lib.file.mkOutOfStoreSymlink "${osConfig.hub.dir}/config/aerc";
  };

  home.sessionVariables.BROWSER = "zen-beta";
}
