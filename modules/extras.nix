# Small optional features, one flag each (hosts/<host>/features.nix).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  f = config.hub.features;
  on = name: f.${name} or false;
in
{
  config = lib.mkMerge [
    # `hub firmware`: BIOS and device firmware updates from LVFS
    (lib.mkIf (on "firmware") { services.fwupd.enable = true; })

    # Kill the hungriest process before the machine freezes when RAM runs out
    (lib.mkIf (on "oom") {
      services.earlyoom = {
        enable = true;
        enableNotifications = true;
      };
    })

    # The clock follows where you are (location via geoclue)
    (lib.mkIf (on "timezone") {
      services.automatic-timezoned.enable = true;
      time.timeZone = lib.mkForce null;
    })

    # `night`: warmer screen after sunset, for the place in config/eww/weather.conf
    (lib.mkIf (on "nightlight") { environment.systemPackages = [ pkgs.wlsunset ]; })

    # `distrobox`: other distributions as containers sharing your home
    (lib.mkIf (on "boxes") { environment.systemPackages = [ pkgs.distrobox ]; })

    # Notifications when the battery is low or the charger changes
    (lib.mkIf (on "batteryAlert") { home-manager.users.oktav.services.poweralertd.enable = true; })
  ];
}
