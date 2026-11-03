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
    # "input"
  ];

  environment.systemPackages = [ pkgs.sc-controller ];
  services.udev.packages = [ pkgs.sc-controller ];

  systemd.user.services.scc-daemon = {
    description = "SC Controller daemon";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    path = [ "/run/current-system/sw" ];
    serviceConfig = {
      ExecStart = "${pkgs.sc-controller}/bin/scc-daemon /dev/null debug";
      Restart = "on-failure";
      TimeoutStopSec = 3;
    };
  };

  services.udev.extraRules = ''
    KERNEL=="hidraw*", KERNELS=="*054C:0CE6*", GROUP="uinput", MODE="0660"
  '';

  # ignore dualsense so sc-contoller is only one to handle it
  environment.sessionVariables.SDL_GAMECONTROLLER_IGNORE_DEVICES = "0x054c/0x0ce6";

}
