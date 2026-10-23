{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{

  home-manager.users.stybr.imports = [
    ../home/gui.nix
  ];

  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/stybr";
    logs = {
      save = true;
      path = "/tmp/dms-greeter.log";
    };
  };

  programs.niri = {
    enable = true;
  };

  programs.dsearch = {
    enable = true;
    systemd.enable = true;
  };

  programs.kdeconnect = {
    enable = true;
  };

  services.xserver.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  services.upower = {
    enable = true;
  };

  services.libinput.enable = true;

  services.gvfs.enable = true;

  programs.firefox.enable = true;

  programs.localsend.enable = true;

  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
    GTK_IM_MODULE = "simple";
  };

  environment.systemPackages = with pkgs; [
    pulseaudio
    xwayland-satellite
  ];

}
