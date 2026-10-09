{
  pkgs,
  lib,
  config,
  ...
}:
let
  roamDir = "${config.home.homeDirectory}/Documents/roam";

  roamBackup = pkgs.writeShellApplication {
    name = "roam-backup";
    runtimeInputs = [
      pkgs.git
      pkgs.openssh
      pkgs.coreutils
    ];
    text = ''
      git add -A
      if ! git diff --cached --quiet; then
        git commit -m "Auto backup $(date '+%Y-%m-%d %H:%M')"
      fi
      git push
    '';
  };
in
{
  systemd.user.services.roam-backup = {
    Unit.Description = "Git backup of the roam";
    Service = {
      Type = "oneshot";
      WorkingDirectory = roamDir;
      ExecStart = lib.getExe roamBackup;
    };
  };

  systemd.user.timers.roam-backup = {
    Unit.Description = "Hourly backup of the roam-backup";
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
