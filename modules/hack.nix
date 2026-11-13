# `hack` profile: a second system variant for security work, selectable in
# the boot menu or live with `mode hack`. Differences from the normal system:
# no Tailscale, no LAN services, random MAC per network, VPN kill-switch on.
{ lib, pkgs, ... }:

{
  specialisation.hack.configuration = {
    system.nixos.tags = [ "hack" ];

    services.tailscale.enable = lib.mkForce false;
    services.avahi.enable = lib.mkForce false;
    programs.localsend.enable = lib.mkForce false;
    services.printing.enable = lib.mkForce false;

    networking.wireless.iwd.settings.General.AddressRandomization = "network";

    systemd.services.vpn-killswitch = {
      description = "Mullvad lockdown mode: no traffic outside the VPN";
      wantedBy = [ "multi-user.target" ];
      after = [ "mullvad-daemon.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = [
          "${pkgs.mullvad}/bin/mullvad lockdown-mode set on"
          "${pkgs.mullvad}/bin/mullvad connect"
        ];
        ExecStop = "${pkgs.mullvad}/bin/mullvad lockdown-mode set off";
      };
    };
  };
}
