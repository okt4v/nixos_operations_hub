# GUI applications.
{
  inputs,
  config,
  lib,
  pkgs,
  unstable,
  ...
}:

{
  home.packages = with pkgs; [
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    thunderbird
    keepassxc
    spotify
    mullvad-vpn # GUI; the daemon is in modules/network.nix
    obsidian
    anki-bin
    zotero
    onlyoffice-desktopeditors
    unstable.vscode # ponytail: fails to build on 26.05 (patchPhase); back to stable once fixed
    gimp
    inkscape # also `fig`
    qalculate-gtk
    goldendict-ng
    (pkgs.callPackage ../pkgs/openscreen.nix { })
    # Chess
    en-croissant
    stockfish
    gnuchess
    fairymax
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

  home.sessionVariables.BROWSER = "zen-beta";
}
