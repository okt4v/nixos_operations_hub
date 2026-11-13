# Local snapshots of /home (btrfs + snapper). The system itself needs none:
# NixOS generations already roll it back.
#   snapper -c home list          browse
#   /home/.snapshots/<n>/snapshot/oktav/...   copy a file back
{ lib, ... }:

{
  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "1d";
    configs.home = {
      SUBVOLUME = "/home";
      ALLOW_USERS = [ "oktav" ];
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_LIMIT_HOURLY = 24;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 3;
      TIMELINE_LIMIT_YEARLY = 0;
    };
  };

  # Snapshots stop at subvolume boundaries, so big, replaceable or
  # constantly-churning directories get their own subvolume ("v") and stay
  # out. VM images additionally skip copy-on-write ("+C").
  systemd.tmpfiles.rules = [
    # First, so the rules below cannot create the home directory as root.
    "d /home/oktav 0700 oktav users -"
    "d /home/oktav/tec 0755 oktav users -"
    "v /home/oktav/tec/vm 0755 oktav users -"
    "h /home/oktav/tec/vm - - - - +C"
    "v /home/oktav/dl 0755 oktav users -"
    "v /home/oktav/.cache 0755 oktav users -"
    "d /home/oktav/.local 0755 oktav users -"
    "d /home/oktav/.local/share 0755 oktav users -"
    "v /home/oktav/.local/share/Steam 0755 oktav users -"
  ];

  # The plain test VM has no btrfs.
  virtualisation.vmVariant.services.snapper.configs = lib.mkForce { };
}
