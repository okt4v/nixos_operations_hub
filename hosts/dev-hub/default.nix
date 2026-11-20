# dev-hub: ThinkPad E16 Gen 2. A host is its imports plus its hardware quirks.
{ pkgs, ... }:

{
  imports = [
    ./hardware.nix
    (import ../../modules/workstation.nix (import ./features.nix))
  ];

  hub.disk = "/dev/nvme0n1";

  # ── Wifi ─────────────────────────────────────────────────────────────────
  # rtw89 (RTL8852CE) drops/reconnects randomly with power save on.
  boot.extraModprobeConfig = "options rtw89_core disable_ps_mode=1";

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
}
