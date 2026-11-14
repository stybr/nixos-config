{
  pkgs,
  ...
}:

{
  programs.openlogi.enable = true;

  systemd.user.services.openlogi-agent = {
    description = "OpenLogi background agent";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.openlogi}/bin/openlogi-agent";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
