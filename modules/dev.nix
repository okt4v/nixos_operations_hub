# System side of development: containers and running foreign binaries.
{
  pkgs,
  options,
  ...
}:

{
  virtualisation.docker.enable = true;
  users.users.oktav.extraGroups = [ "docker" ];

  # Excalidraw on demand: `excalidraw-start` / `excalidraw-stop`.
  virtualisation.oci-containers = {
    backend = "docker";
    containers.excalidraw = {
      image = "excalidraw/excalidraw:latest";
      ports = [ "3002:80" ];
      autoStart = false;
    };
  };

  # Local dev servers reachable from the LAN (phone testing).
  networking.firewall.allowedTCPPorts = [
    8000
    8080
  ];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Lets prebuilt dynamic binaries run (uv-managed Pythons, npm globals,
  # claude). The extra libraries are the Electron runtime set.
  programs.nix-ld = {
    enable = true;
    libraries =
      options.programs.nix-ld.libraries.default
      ++ (with pkgs; [
        glib
        nspr
        nss
        at-spi2-core
        cups.lib
        dbus.lib
        cairo
        gtk3
        pango
        gdk-pixbuf
        libx11
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
        libxcb
        libxshmfence
        libgbm
        libdrm
        libGL
        expat
        libxkbcommon
        systemd
        alsa-lib
      ]);
  };
}
