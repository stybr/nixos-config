{ ... }:

{

  services.tailscale = {
    enable = true;
    openFirewall = true;
    extraSetFlags = [ "--operator=stybr" ];
  };

}
