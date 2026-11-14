# dev-hub: ThinkPad E16 Gen 2. A host is its imports plus its hardware quirks.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Which features are on: features.nix, edited by `hub feature`.
  f = import ./features.nix;
  on = flag: module: if flag then [ module ] else [ ];
in
{
  imports = [
    ./hardware.nix
    ../../modules/core.nix
    ../../modules/disk.nix
    ../../modules/desktop.nix
    ../../modules/home-manager.nix
    ../../modules/network.nix
    ../../modules/secrets.nix
    ../../modules/backup.nix
    ../../modules/boot.nix
    ../../modules/ai.nix
  ]
  ++ on f.keyboard ../../modules/keyboard.nix
  ++ on f.dev ../../modules/dev.nix
  ++ on f.lab ../../modules/lab.nix
  ++ on f.hack ../../modules/hack.nix
  ++ on f.play ../../modules/play.nix
  ++ on f.meetings ../../modules/meetings.nix
  ++ on f.minutes ../../modules/minutes.nix
  ++ on f.snapshots ../../modules/snapshots.nix
  ++ on f.power ../../modules/power.nix
  ++ on f.phone ../../modules/phone.nix
  ++ on f.mail ../../modules/mail.nix
  ++ on f.freshRoot ../../modules/fresh-root.nix;

  hub.features = f;
  hub.cal.enable = f.calendar;
  hub.ai.enable = f.ai;
  hub.secureBoot.enable = f.secureBoot;
  hub.backup.external.enable = f.backupExternal;
  hub.backup.homelab.enable = f.backupHomelab;
  hub.backup.cloud.enable = f.backupCloud;

  hub.disk = "/dev/nvme0n1";

  # ── Wifi ─────────────────────────────────────────────────────────────────
  networking.wireless.iwd.enable = true;

  # rtw89 (RTL8852CE) drops/reconnects randomly with power save on.
  boot.extraModprobeConfig = "options rtw89_core disable_ps_mode=1";

  # iwd's default roam thresholds are too eager on a multi-AP mesh: it
  # ping-ponged between APs every ~60s at good signal. Roam only when signal is
  # actually poor, and back off the retry cadence.
  networking.wireless.iwd.settings.General = {
    RoamThreshold = -75;
    RoamThreshold5G = -80;
    RoamRetryInterval = 300;
  };

  # Only advertise AirPlay on real NICs, otherwise avahi also publishes the
  # docker/libvirt bridge IPs and clients try those unroutable addresses.
  services.avahi.allowInterfaces = [
    "wlan0"
    "enp2s0"
  ];

  # ── Audio ────────────────────────────────────────────────────────────────
  # Prefer the HDMI output of this machine's GPU over the internal speakers.
  services.pipewire.wireplumber.extraConfig."50-hdmi-priority"."monitor.alsa.rules" = [
    {
      matches = [ { "node.name" = "~alsa_output.pci-0000_04_00.1.*"; } ];
      actions.update-props."priority.session" = 1100;
    }
  ];

  # The mic-mute LED doesn't track mute state on its own: the AMD ACP mic has
  # no hardware mute switch, PipeWire mutes in software, so the kernel's LED
  # trigger never fires (alsa-project/alsa-ucm-conf#100). Disable the dead
  # trigger and let config/sway/scripts/micmute-led-sync.sh drive the LED.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="platform::micmute", RUN+="${pkgs.writeShellScript "micmute-led-setup" ''
      echo none > "/sys/class/leds/$1/trigger"
      chgrp input "/sys/class/leds/$1/brightness"
      chmod g+w "/sys/class/leds/$1/brightness"
    ''} %k"
  '';

  # ── GPU ──────────────────────────────────────────────────────────────────
  # OpenCL/HIP for the Radeon 680M. It (gfx1035) isn't on ROCm's allowlist;
  # the override makes Blender's HIP backend and ollama accept it.
  hardware.graphics.extraPackages = with pkgs; [
    rocmPackages.clr
    rocmPackages.clr.icd
  ];
  environment.sessionVariables.HSA_OVERRIDE_GFX_VERSION = "10.3.0";

  # ── VM test harness (`just vm`) ──────────────────────────────────────────
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
      # swayfx needs GLES; virgl provides it inside QEMU.
      qemu.options = [ "-device virtio-vga-gl" ];
    };
  };
}
