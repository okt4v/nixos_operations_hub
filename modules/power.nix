# Laptop power care.
{ pkgs, ... }:

let
  threshold = "/sys/class/power_supply/BAT0/charge_control_end_threshold";
in
{
  # Stop charging at 80% to slow battery wear. `hub charge full` lifts the
  # cap until the next boot.
  systemd.tmpfiles.rules = [ "w ${threshold} - - - - 80" ];

  # Follow the charger: power-saver on battery, balanced on AC. A mode or the
  # bar can still override it until the next plug event.
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced"
  '';
}
