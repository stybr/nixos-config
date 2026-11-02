{ config, ... }:

{

  services.rustical = {
    enable = true;
    settings.http.bind = "0.0.0.0:4000";
  };

  systemd.services.tailscale-serve-rustical = {
    after = [
      "tailscaled.service"
      "rustical.service"
    ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ config.services.tailscale.package ];
    script = "tailscale serve --bg 4000";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

}
