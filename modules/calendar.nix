{ ... }:

{

  services.radicale = {
    enable = true;
    settings = {
      server.hosts = [ "0.0.0.0:5232" ];
      auth.type = "none";
    };

  };

  networking.firewall.interfaces.tailscale0.allowTCPPorts = [ 5232 ];

}
