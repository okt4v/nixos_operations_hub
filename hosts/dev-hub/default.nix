# dev-hub: ThinkPad E16 Gen 2. A host is its imports plus its hardware quirks.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ../../modules/core.nix
    ../../modules/disk.nix
    ../../modules/desktop.nix
    ../../modules/keyboard.nix
    ../../modules/home-manager.nix
    ../../modules/dev.nix
    ../../modules/lab.nix
    ../../modules/play.nix
    ../../modules/snapshots.nix
    ../../modules/backup.nix
    ../../modules/secrets.nix
    ../../modules/boot.nix
    ../../modules/power.nix
    ../../modules/network.nix
    ../../modules/meetings.nix
    ../../modules/ai.nix
    ../../modules/hack.nix
  ];

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
