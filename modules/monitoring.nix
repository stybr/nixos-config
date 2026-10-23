{ ... }:

{
  services.beszel.hub = {
    enable = true;
    host = "0.0.0.0";
  };

  networking.firewall.allowedTCPPorts = [ 8090 ];
}
