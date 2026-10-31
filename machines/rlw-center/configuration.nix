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

  fileSystems."/mnt/games" = {
    device = "192.168.50.214:/data/games";
    fsType = "nfs";
    options = [
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10s"
    ];
  };

}
