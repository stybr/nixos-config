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

  # services.deluge = {
  #   enable = true;
  #   web.enable = true;
  #   user = "stybr";
  #   group = "users";
  #   dataDir = "/home/stybr/.config/deluge";
  # };

  services.qbittorrent = {
    enable = true;
    openFirewall = true;
    webuiPort = 8080;
    user = "stybr";
    group = "users";
    serverConfig = {
      Preferences.WebUI = {
        Username = "stybr";
        Password_PBKDF2 = "@ByteArray(goFFe0Lzqq1s2hkHr1njtA==:iaLpirCE3kQr47TcYkzKO322YPuMgVN247a6J/W/0aKMGc9fVdKrGeG9xZvgKAYri3hDaTaTCsZVDwPOCqTGFw==)";
        AlternativeUIEnabled = true;
        RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
        # LocalHostAuth = false;
      };
    };
  };

  systemd.services.qbittorrent.serviceConfig.ProtectHome = lib.mkForce false;

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
    kdePackages.kio-fuse
    kdePackages.kio-extras
    nemo
    pcmanfm
    geogebra6
    qutebrowser
    brave
    brave-origin
    libreoffice
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
