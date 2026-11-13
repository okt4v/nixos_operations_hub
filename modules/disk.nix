# Whole-disk layout: 1G ESP + LUKS2 -> btrfs subvolumes. A host picks the
# disk with `hub.disk = "/dev/...";`. Installing WIPES that disk; for dual
# boot see docs/INSTALL.md instead of running disko.
{
  inputs,
  config,
  lib,
  ...
}:

let
  opts = [
    "compress=zstd"
    "noatime"
  ];
in
{
  imports = [ inputs.disko.nixosModules.disko ];

  options.hub.disk = lib.mkOption {
    type = lib.types.str;
    example = "/dev/nvme0n1";
    description = "The disk this host is installed on.";
  };

  config.disko.devices.disk.main = {
    type = "disk";
    device = config.hub.disk;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "crypt";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = [
                "-f"
                "-L"
                "nixos"
              ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = opts;
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = opts;
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = opts;
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = opts;
                };
                # snapper keeps /home snapshots here, outside @home itself
                "@snapshots" = {
                  mountpoint = "/home/.snapshots";
                  mountOptions = opts;
                };
              };
            };
          };
        };
      };
    };
  };

  config.fileSystems."/var/log".neededForBoot = true;
}
