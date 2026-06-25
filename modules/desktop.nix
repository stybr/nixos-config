{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{

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

  services.deluge = {
    enable = true;
    web.enable = true;
    user = "stybr";
    group = "users";
    dataDir = "/home/stybr/.config/deluge";
  };

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

  programs.firefox.enable = true;

  environment.sessionVariables = {
    GTK_IM_MODULE = "simple";
  };

  environment.systemPackages = with pkgs; [
    (tree-sitter.withPlugins (_: tree-sitter.allGrammars))
    filezilla
    tela-icon-theme
    papirus-icon-theme
    adwaita-icon-theme
    kid3
    libsForQt5.qt5ct
    kdePackages.qt6ct
    kdePackages.kdenlive
    kdePackages.dolphin
    nemo
    pcmanfm
    geogebra6
    qutebrowser
    brave
    libreoffice-fresh
    faugus-launcher
    upscayl
    thunderbird
    tor-browser
    docker
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtwayland
    chromium
    gnucash
    discord
    vscode
    blender
    obs-studio
    gimp
    localsend
    signal-desktop
    emacs-pgtk
    pulseaudio
    imv
    mpv
    overskride
    texliveFull
    zathura
    ghostty
    cava
    xwayland-satellite
  ];

}
