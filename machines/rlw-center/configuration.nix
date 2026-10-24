{ ... }:

{

  networking.hostName = "rlw-center";

  clan.core.networking.targetHost = "root@192.168.50.59";

  zramSwap.enable = true;

  services.openssh.settings.KbdInteractiveAuthentication = false;

  services.displayManager.autoLogin = {
    enable = true;
    user = "stybr";
  };

}
