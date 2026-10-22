{
  config,
  inputs,
  pkgs,
  ...
}:

{

  imports = [
    inputs.zen-browser.homeModules.twilight
    inputs.dms.homeModules.dank-material-shell
    inputs.dms-plugin-registry.homeModules.default
    inputs.dcal.homeModules.default
    inputs.dfiles.homeModules.default
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "org.pwmt.zathura.desktop";
    };
  };

  programs.dank-material-shell = {

    enable = true;

    settings = {
      currentThemeName = "dynamic";
      currentThemeCategory = "dynamic";
      matugenScheme = "scheme-tonal-spot";
      blurWallpaperOnOverview = true;
      wallpaperFillMode = "Fill";
      # frameEnabled = true;
      #
      barConfigs = [
        {
          id = "default";
          name = "Main Bar";
          enabled = true;
          island = true;
          islandNotch = true;
          position = 0;
          widgetPadding = 8;
          leftWidgets = [
            # "launcherButton"
            "dankPomodoroTimer"
            "workspaceSwitcher"
            "focusedWindow"
          ];
          centerWidgets = [
            "dankKDEConnect"
            # "music"
            "clock"
            "weather"
            "keyboard_layout_name"
          ];
          rightWidgets = [
            "systemTray"
            "clipboard"
            "cpuUsage"
            "memUsage"
            "notificationButton"
            "battery"
            "controlCenterButton"
          ];
        }
      ];

      dockConfigs = [
        {
          id = "dock";
          name = "Dock";
          enabled = true;
          position = 1;
          autoHide = true;
          launcherLogoMode = "apps";
          showTrash = true;
        }
      ];
    };

    session = {
      wallpaperPath = "${config.home.homeDirectory}/Pictures/wallpapers/hip-hop/Future-2016-Lollapalooza-James_Richards_IV-2.jpg";
      weatherLocation = "Pilsen, CZ";
      weatherCoordinates = "49.7475,13.3776";
      dockPins = {
        dock = [
          "zen-twilight"
          "dev.duxlabs.files"
          "heroic"
        ];
      };
    };

    plugins = {
      dankPomodoroTimer.enable = true;
      dankKDEConnect.enable = true;
      dankStickerSearch.enable = true;
      dankGifSearch.enable = true;
    };

    #quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;
    quickshell.package = pkgs.quickshell;

    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    enableSystemMonitoring = true;
    enableVPN = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = false;
  };

  programs.dank-calendar = {
    enable = true;
    systemd = {
      enable = true;
    };
  };

  programs.dux-files = {
    enable = true;

    systemd = {
      enable = true;
      target = "graphical-session.target";
      restartIfChanged = true;
    };

    portal = {
      enable = true; # register the dfiles backend with xdg-desktop-portal
      preferred = true; # prefer it for org.freedesktop.impl.portal.FileChooser
      desktop = "niri"; # which xdg.portal.config entry gets the preference, "common" by default
    };
  };

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
  };

  programs.zathura = {
    enable = true;
  };

  programs.brave.enable = true;
  programs.brave-origin.enable = true;
  programs.chromium.enable = true;
  programs.qutebrowser.enable = true;

  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
  };

  services.emacs = {
    enable = true;
    startWithUserSession = "graphical";
  };

  programs.ghostty.enable = true;
  programs.cava.enable = true;
  programs.mpv.enable = true;
  programs.imv.enable = true;
  programs.obs-studio.enable = true;
  programs.libreoffice.enable = true;
  programs.discord.enable = true;
  programs.vscode.enable = true;

  home.packages = with pkgs; [
    (tree-sitter.withPlugins (_: tree-sitter.allGrammars))
    (hunspell.withDicts (d: [
      d.en_US
      d.cs_CZ
    ]))
    papirus-icon-theme
    thunderbird
    texliveFull
    tela-icon-theme
    adwaita-icon-theme
    filezilla
    kid3
    kdePackages.kdenlive
    nemo
    pcmanfm
    geogebra6
    faugus-launcher
    upscayl
    tor-browser
    gnucash
    blender
    gimp
    signal-desktop
    overskride
    libsForQt5.qt5ct
    kdePackages.qt6ct
  ];

}
