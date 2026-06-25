{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.zen-browser.homeModules.twilight
    inputs.dms.homeModules.dank-material-shell
    inputs.dms-plugin-registry.nixosModules.default
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
      barConfigs = [
        {
          id = "default";
          name = "Main Bar";
          enabled = true;
          position = 3;
          widgetPadding = 8;
          leftWidgets = [
            "launcherButton"
            "workspaceSwitcher"
            "focusedWindow"
          ];
          centerWidgets = [
            "music"
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
    };

    session = {
      wallpaperPath = "${config.home.homeDirectory}/Pictures/wallpapers/hip-hop/future-1.webp";
      weatherLocation = "Pilsen, CZ";
      weatherCoordinates = "49.7475,13.3776";
    };

    plugins = {
      dankBatteryAlerts.enable = true;
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
    enableCalendarEvents = true;

  };

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
  };

  home.username = "stybr";
  home.homeDirectory = "/home/stybr";
  home.stateVersion = "25.05";

  programs.ssh = {
    enable = true;
  };

  services.udiskie = {
    enable = true;
  };

  programs.beets = {
    enable = true;
    settings = {
      directory = "~/Music/beets";
      library = "~/Music/beets/library.db";
      import = {
        copy = true;
      };
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Antonín Štýbr";
        email = "antonin@stybr.com";
      };
      init.defaultBranch = "main";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
    };
  };

  programs.vdirsyncer = {
    enable = true;
  };

  programs.fish = {
    enable = true;
    generateCompletions = true;
    shellInit = ''
      set -gx EDITOR "emacsclient -c"
      set -gx SUDO_EDITOR "emacsclient -c"
      fish_add_path $HOME/.local/bin
      fish_add_path $HOME/.config/emacs/bin
      fish_vi_key_bindings
    '';
    shellAbbrs = {
      low = "libreoffice --writer";
      loc = "libreoffice --calc";
      loi = "libreoffice --impress";
      lod = "libreoffice --draw";
      yda = "yt-dlp -f ba --embed-metadata --embed-thumbnail --embed-chapters -x --download-archive .archive-file";
      ydav = "yt-dlp -f b --embed-metadata --embed-thumbnail --embed-chapters -x --download-archive .archive-file";
      nrs = "sudo nixos-rebuild switch --flake /home/stybr/nixos-config";
      nfu = "sudo nix flake update --flake /home/stybr/nixos-config";
      g = "git";
      s = "sudo";
      gc = "git clone";
      z = "zathura --mode=fullscreen";
      se = "sudoedit";
      ec = "emacsclient -c";
      sec = "sudoedit /etc/nixos/modules/common.nix";
      seh = "sudoedit /etc/nixos/home/common.nix";
      sef = "sudoedit /etc/nixos/flake.nix";
      sse = "sudo systemctl enable --now";
      ssd = "sudo systemctl disable";
      ssr = "sudo systemctl restart";
      ss = "systemctl status";
      sus = "systemctl --user status";
      sue = "systemctl --user enable --now";
      sud = "systemctl --user disable";
      sur = "systemctl --user restart";
      sure = "systemctl --user restart emacs";
      tp = "trash put";
      te = "trash empty";
      cx = "chmod a+x";
      pk = "k";
    };

  };

}
