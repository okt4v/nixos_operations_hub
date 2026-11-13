# Off-machine backups with restic. Both targets are off until they exist:
#   hub.backup.external.enable = true;   USB drive, run by hand: `hub bak`
#   hub.backup.homelab.enable  = true;   server over SSH, daily
# The repository password is the sops secret `restic` (see modules/secrets.nix).
{ config, lib, ... }:

let
  cfg = config.hub.backup;
  common = {
    paths = [ "/home/oktav" ];
    exclude = [
      "/home/oktav/.cache"
      "/home/oktav/dl"
      "/home/oktav/tec/vm"
      "/home/oktav/vlt" # the mounted vault; its ciphertext in dat/vlt IS backed up
      "/home/oktav/.local/share/Steam"
      "/home/oktav/.local/share/containers"
      "**/node_modules"
      "**/.venv"
      "**/.direnv"
      "**/target"
    ];
    passwordFile = config.sops.secrets.restic.path;
    initialize = true;
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
  };
in
{
  options.hub.backup = {
    external = {
      enable = lib.mkEnableOption "restic backup to an external drive";
      repo = lib.mkOption {
        type = lib.types.str;
        default = "/run/media/oktav/bak/restic";
        description = "Repository path on the mounted drive (label the filesystem `bak`).";
      };
    };
    homelab = {
      enable = lib.mkEnableOption "daily restic backup to a homelab server";
      repo = lib.mkOption {
        type = lib.types.str;
        example = "sftp:nas:/srv/restic/dev-hub";
        description = "restic repository URL on the server.";
      };
    };
  };

  config = lib.mkIf (cfg.external.enable || cfg.homelab.enable) {
    sops.secrets.restic = { };

    services.restic.backups = {
      external = lib.mkIf cfg.external.enable (
        common
        // {
          repository = cfg.external.repo;
          timerConfig = null; # only when the drive is plugged in and you ask
        }
      );
      homelab = lib.mkIf cfg.homelab.enable (
        common
        // {
          repository = cfg.homelab.repo;
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
        }
      );
    };
  };
}
