{ ... }:

{
  services.beszel.hub = {
    enable = true;
    host = "0.0.0.0";
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8090 ];
}
