# Calendar (iCloud -> local, khal) and time tracking.
{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:

let
  live = path: config.lib.file.mkOutOfStoreSymlink "${osConfig.hub.dir}/${path}";
in
{
  home.packages = with pkgs; [
    vdirsyncer
    khal
    timewarrior
  ];

  xdg.configFile = {
    "vdirsyncer/config".source = live "config/calendar/vdirsyncer.conf";
    "khal/config".source = live "config/calendar/khal.conf";
    # An existing config stops timewarrior's interactive first-run question.
    "timewarrior/timewarrior.cfg".text = "";
  };

  # ...and an existing database stops the second one.
  home.activation.timewData = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.xdg.dataHome}/timewarrior/data"
  '';

  # Runs only once the iCloud password secret exists (hub.cal.enable).
  systemd.user.services.vdirsyncer = {
    Unit = {
      Description = "Sync calendars";
      ConditionPathExists = "/run/secrets/icloud";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.vdirsyncer}/bin/vdirsyncer sync";
    };
  };
  systemd.user.timers.vdirsyncer = {
    Unit.Description = "Sync calendars every 15 minutes";
    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "15m";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # Notes vault: an hourly commit gives every note a history.
  systemd.user.services.notes-commit = {
    Unit.Description = "Commit changes in ~/doc/notes";
    Service = {
      Type = "oneshot";
      WorkingDirectory = "%h/doc/notes";
      ExecStart = "${pkgs.writeShellScript "notes-commit" ''
        export PATH=${pkgs.git}/bin:$PATH
        [ -d .git ] || git init -q
        git add -A
        git diff --cached --quiet || git -c commit.gpgsign=false commit -q --no-verify -m "notes $(date '+%F %H:%M')"
      ''}";
    };
  };
  systemd.user.timers.notes-commit = {
    Unit.Description = "Hourly notes commit";
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
