# Network trust. On wifi networks not listed in `hub.net.trusted` the VPN is
# forced on and local sharing (AirPlay, LocalSend discovery) is stopped.
# With an empty list this does nothing, so nothing changes until you opt in:
#   hub.net.trusted = [ "home-ssid" "school-ssid" ];
# `mode travel` forces the untrusted behaviour everywhere.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  trusted = config.hub.net.trusted;
  trust = pkgs.writeShellApplication {
    name = "net-trust";
    runtimeInputs = with pkgs; [
      iwd
      gawk
      mullvad
      systemd
      procps
    ];
    text = ''
      # net-trust [untrusted|auto] — apply the policy for the current network
      ssid=$(iwctl station wlan0 show 2>/dev/null | awk '/Connected network/ { $1=$2=""; sub(/^ +/, ""); sub(/ +$/, ""); print }')
      state=untrusted
      if [ "''${1:-auto}" = auto ]; then
        while IFS= read -r t; do [ "$ssid" = "$t" ] && state=trusted; done < ${pkgs.writeText "trusted-wifi" (lib.concatLines trusted)}
        [ -z "$ssid" ] && state=trusted # wired or offline: nothing to protect against
      fi
      if [ "$state" = trusted ]; then
        mullvad lockdown-mode set off || true
        systemctl start avahi-daemon.socket avahi-daemon.service || true
      else
        mullvad lockdown-mode set on || true
        mullvad connect || true
        systemctl stop avahi-daemon.socket avahi-daemon.service || true
        pkill -x kdeconnectd || true # phone link: no pairing offers to strangers
      fi
      echo "$state" > /run/net-trust
    '';
  };
in
{
  options.hub.focus.sites = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [
      "youtube.com"
      "reddit.com"
      "x.com"
      "twitter.com"
      "instagram.com"
      "tiktok.com"
      "twitch.tv"
      "netflix.com"
    ];
    description = "Domains unreachable during a `focus` block.";
  };

  options.hub.net.trusted = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Wifi SSIDs considered safe.";
  };

  config = {
    services.mullvad-vpn.enable = true;

    # Homelab mesh. Log in once with `sudo tailscale up`; `hp` lists the hosts.
    services.tailscale.enable = true;
    environment.systemPackages = [ trust ];

    # Re-evaluate whenever an address appears or disappears.
    systemd.services.net-trust = lib.mkIf (trusted != [ ]) {
      description = "Apply network trust policy on network changes";
      wantedBy = [ "multi-user.target" ];
      after = [ "mullvad-daemon.service" ];
      serviceConfig.Restart = "always";
      script = ''
        ${trust}/bin/net-trust auto
        ${pkgs.iproute2}/bin/ip -o monitor address | while read -r _; do
          ${trust}/bin/net-trust auto
        done
      '';
    };

    # While active, a hosts file that sends the focus sites nowhere is mounted
    # over /etc/hosts. `focus` starts and stops it.
    systemd.services.focus-block =
      let
        blocked = pkgs.writeText "focus-sites" (
          lib.concatMapStrings (d: "0.0.0.0 ${d} www.${d}\n:: ${d} www.${d}\n") config.hub.focus.sites
        );
        hosts =
          pkgs.runCommand "focus-hosts" { }
            "cat ${config.environment.etc.hosts.source} ${blocked} > $out";
      in
      {
        description = "Block distracting sites (focus)";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.util-linux}/bin/mount --bind ${hosts} /etc/hosts";
          ExecStop = "${pkgs.util-linux}/bin/umount /etc/hosts";
        };
      };

    # `mode travel` may flip the policy without a password.
    security.sudo.extraRules = [
      {
        users = [ "oktav" ];
        commands = [
          {
            command = "${trust}/bin/net-trust";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemctl start focus-block";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemctl stop focus-block";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
