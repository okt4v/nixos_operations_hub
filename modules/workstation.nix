# The desktop machine every workstation host shares: modules, feature flags,
# wifi, the `hub vm` harness. A host imports it with its own flags:
#   (import ../../modules/workstation.nix (import ./features.nix))
# and keeps only its hardware quirks in hosts/<host>/default.nix.
f:
{ config, lib, ... }:

let
  on = flag: module: if flag then [ module ] else [ ];
in
{
  imports = [
    ./core.nix
    ./disk.nix
    ./desktop.nix
    ./home-manager.nix
    ./network.nix
    ./secrets.nix
    ./backup.nix
    ./boot.nix
    ./ai.nix
    ./extras.nix
  ]
  ++ on f.keyboard ./keyboard.nix
  ++ on f.dev ./dev.nix
  ++ on f.lab ./lab.nix
  ++ on f.hack ./hack.nix
  ++ on f.play ./play.nix
  ++ on f.meetings ./meetings.nix
  ++ on f.minutes ./minutes.nix
  ++ on f.snapshots ./snapshots.nix
  ++ on f.power ./power.nix
  ++ on f.phone ./phone.nix
  ++ on f.mail ./mail.nix
  ++ on f.freshRoot ./fresh-root.nix
  ++ on f.remoteUnlock ./remote-unlock.nix;

  hub.features = f;
  hub.cal.enable = f.calendar;
  hub.ai.enable = f.ai;
  hub.secureBoot.enable = f.secureBoot;
  hub.backup.external.enable = f.backupExternal;
  hub.backup.homelab.enable = f.backupHomelab;
  hub.backup.cloud.enable = f.backupCloud;

  # ── Wifi ─────────────────────────────────────────────────────────────────
  networking.wireless.iwd.enable = true;
  # iwd's default roam thresholds are too eager on a multi-AP mesh: it
  # ping-ponged between APs every ~60s at good signal. Roam only when signal is
  # actually poor, and back off the retry cadence.
  networking.wireless.iwd.settings.General = {
    RoamThreshold = -75;
    RoamThreshold5G = -80;
    RoamRetryInterval = 300;
  };

  # ── VM test harness (`hub vm`) ───────────────────────────────────────────
  # Not part of the installed system. Shares this checkout at hub.dir so the
  # live-linked dotfiles resolve, and opens SSH on localhost:2222 for checks.
  virtualisation.vmVariant = {
    users.users.oktav.initialPassword = lib.mkForce "test";
    services.openssh.enable = true;
    # QEMU draws the guest's hardware cursor upside down with GL; let sway
    # draw it instead.
    environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
    virtualisation = {
      memorySize = 4096;
      diskSize = 8192; # MB; room for project venvs
      cores = 4;
      forwardPorts = [
        {
          from = "host";
          host.port = 2222;
          guest.port = 22;
        }
      ];
      sharedDirectories.hub = {
        source = ''"$HUB_SRC"'';
        target = config.hub.dir;
        securityModel = "none";
      };
      # swayfx needs GLES; virgl provides it inside QEMU (needs a GPU on the
      # host; hub.vmGl = false without one, as bin/test-tools does)
      qemu.options = lib.optional config.hub.vmGl "-device virtio-vga-gl";
    };
  };
}
