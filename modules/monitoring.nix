{ ... }:

{
  services.beszel.hub = {
    enable = true;
    host = "0.0.0.0";
  };

  services.beszel.agent = {
    enable = true;
    smartmon.enable = true;
    environment.KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBHjEzGq6EHh6D9rTFRtVm47gOzaLKx8c9W+QYSsPtls";
  };

  networking.firewall.allowedTCPPorts = [ 8090 ];
}
