{ pkgs, ... }:

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

  hardware.uinput.enable = true;
  users.users.stybr.extraGroups = [
    "uinput"
    "input"
  ];

  environment.systemPackages = [ pkgs.sc-controller ];
  services.udev.packages = [ pkgs.sc-controller ];

  services.udev.extraRules = ''
    KERNEL=="hidraw*", KERNELS=="*054C:0CE6*", GROUP="input", MODE="0660"
  '';

}
