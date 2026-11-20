# Disk layout: LUKS2 -> btrfs subvolumes. Two ways, both set up by the installer:
#   whole disk (default): 1G ESP + LUKS on `hub.disk`; installing WIPES it.
#   dual boot (hub.dualBoot.enable): next to Windows. The installer adds two
#     partitions in the free space, `nixos-boot` (1G, XBOOTLDR: kernels go
#     here, Windows' ESP is usually too small) and `nixos-crypt`; Windows'
#     own ESP is only mounted at /efi for the boot menu, never formatted.
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
  sub = mountpoint: {
    inherit mountpoint;
    mountOptions = opts;
  };
  crypt = {
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
        "@" = sub "/";
        "@home" = sub "/home";
        "@nix" = sub "/nix";
        "@log" = sub "/var/log";
        # snapper keeps /home snapshots here, outside @home itself
        "@snapshots" = sub "/home/.snapshots";
      };
    };
  };
  dual = config.hub.dualBoot;
in
{
  imports = [ inputs.disko.nixosModules.disko ];

  options.hub.disk = lib.mkOption {
    type = lib.types.str;
    example = "/dev/nvme0n1";
    description = "The disk this host is installed on.";
  };

  options.hub.dualBoot = {
    enable = lib.mkEnableOption "installing next to Windows instead of on the whole disk";
    esp = lib.mkOption {
      type = lib.types.str;
      example = "/dev/disk/by-uuid/1234-ABCD";
      description = "Windows' EFI partition, mounted at /efi for the boot menu.";
    };
  };

  config = lib.mkMerge [
    {
      disko.devices.disk =
        if dual.enable then
          {
            boot = {
              type = "disk";
              device = "/dev/disk/by-partlabel/nixos-boot";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            main = {
              type = "disk";
              device = "/dev/disk/by-partlabel/nixos-crypt";
              content = crypt;
            };
          }
        else
          {
            main = {
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
                    content = crypt;
                  };
                };
              };
            };
          };
      fileSystems."/var/log".neededForBoot = true;
    }
    (lib.mkIf dual.enable {
      fileSystems."/efi" = {
        device = dual.esp;
        fsType = "vfat";
        options = [ "umask=0077" ];
      };
      boot.loader.efi.efiSysMountPoint = "/efi";
      boot.loader.systemd-boot.xbootldrMountPoint = "/boot";
    })
  ];
}
