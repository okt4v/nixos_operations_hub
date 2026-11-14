# Fresh root: / is a RAM disk that starts empty at every boot, so nothing
# undeclared accumulates. What survives a reboot:
#   - everything declared in this repo (it is rebuilt from /nix)
#   - /home, /nix, /var/log (their own subvolumes, as before)
#   - the state in `keep` below, stored on the old root subvolume (/persist)
# The old root is not deleted: switching the feature off and rebooting brings
# the ordinary root back with the same state.
# Your password: `hub passwd` (plain `passwd` would be forgotten at reboot).
{ config, lib, ... }:

let
  disk = config.fileSystems."/home".device;
  # Directories that must outlive a reboot. Add a line when a program loses
  # its state: services keep theirs under /var/lib, which is already here.
  keep = [
    "/var/lib" # docker, libvirt, tailscale, bluetooth, wifi passwords, sbctl
    "/var/tmp" # large temporary files (nix builds) stay off the RAM disk
    "/etc/mullvad-vpn" # VPN account and settings
    "/etc/ssh" # host keys
  ];
  unit = path: "sysroot" + lib.replaceStrings [ "/" ] [ "-" ] path + ".mount";
in
{
  fileSystems = {
    "/" = {
      device = lib.mkForce "none";
      fsType = lib.mkForce "tmpfs";
      options = lib.mkForce [
        "size=25%"
        "mode=755"
      ];
    };
    "/persist" = {
      device = disk;
      fsType = "btrfs";
      neededForBoot = true;
      options = [
        "subvol=@"
        "compress=zstd"
        "noatime"
      ];
    };
  }
  // lib.genAttrs keep (path: {
    device = "/persist${path}";
    fsType = "none";
    neededForBoot = true;
    options = [ "bind" ];
    depends = [ "/persist" ];
  });

  # On a disk that never ran with an ordinary root the kept directories and
  # the machine id do not exist yet.
  boot.initrd.systemd.services.persist-prepare = {
    description = "Prepare /persist for the fresh root";
    wantedBy = [ "initrd-fs.target" ];
    after = [ "sysroot-persist.mount" ];
    requires = [ "sysroot-persist.mount" ];
    before = map unit keep;
    unitConfig.DefaultDependencies = false;
    serviceConfig.Type = "oneshot";
    script = ''
      p=/sysroot/persist
      mkdir -p ${lib.concatMapStringsSep " " (d: "$p${d}") keep}
      [ -s $p/etc/machine-id ] || tr -d - < /proc/sys/kernel/random/uuid > $p/etc/machine-id
    '';
  };

  environment.etc."machine-id".source = "/persist/etc/machine-id";
  # `hub vm` has its own throwaway disk and no /persist
  virtualisation.vmVariant.environment.etc."machine-id".enable = false;

  # The password hash `hub passwd` stores. Without the file the account
  # falls back to the initial password.
  users.users.oktav.hashedPasswordFile = "/persist/etc/hub-password";

  # nix builds need more room than the RAM disk has
  systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";
  security.sudo.extraConfig = "Defaults lecture = never";
}
