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
    #quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;
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

  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = true;
    settings = {
      webService = {
        AllowUnencrypted = true;
      };
    };
  };

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
    kdePackages.dolphin
    kdePackages.kio-fuse
    kdePackages.kio-extras
    pulseaudio
    xwayland-satellite
  ];

}
