{
  pkgs,
  lib,
  ...
}:

let
  libs32 = pkgs.buildEnv {
    name = "nix-ld-libs-i686";
    pathsToLink = [ "/lib" ];
    ignoreCollisions = true;
    paths = map lib.getLib (
      with pkgs.pkgsi686Linux;
      [
        stdenv.cc.cc
        udev
        zlib
        libGL
        vulkan-loader
        alsa-lib
        libpulseaudio
        libX11
        libXcursor
        libXrandr
        libXi
        libXext
        libXinerama
        openal
        SDL2
      ]
    );
  };

  gameLibrary = pkgs.callPackage ../pkgs/game-library { };

  games = pkgs.writeShellApplication {
    name = "games";
    runtimeInputs = [ pkgs.chromium ];
    text = ''
      exec chromium --app=http://127.0.0.1:8765 --start-fullscreen \
        --password-store=basic \
        --user-data-dir="$HOME/.local/share/game-library/chromium"
    '';
  };

  # games = pkgs.writeShellApplication {
  #   name = "games";
  #   runtimeInputs = [ pkgs.zenity ];
  #   text = ''
  #     cd /mnt/games
  #     game=$(printf '%s\n' ./*-jc141/*.sh | grep -v '/actions\.sh$' | sed 's|^\./||' \
  #       | zenity --list --title=Games --column=Game --width=700 --height=700) || exit 0
  #     cd "$(dirname "$game")"
  #     exec bash "$(basename "$game")"
  #   '';
  # };

  gamesDesktop = pkgs.makeDesktopItem {
    name = "games";
    desktopName = "Games";
    exec = "games";
    icon = "applications-games";
    categories = [ "Game" ];
  };

in
{

  programs.gamescope.enable = true;
  programs.gamemode.enable = true;

  home-manager.users.stybr.programs.dank-material-shell.session.dockPins.dock = lib.mkAfter [
    "games"
  ];

  home-manager.users.stybr.systemd.user.services.game-library = {
    Unit = {
      Description = "Game library backend";
      PartOf = [ "graphical-session.target" ]; # skončí s grafickým sezením
      After = [ "graphical-session.target" ]; # až když je WAYLAND_DISPLAY a spol.
    };
    Service = {
      ExecStart = lib.getExe gameLibrary;
      Restart = "on-failure";
      KillMode = "process"; # při restartu ukončit jen backend, spuštěná hra běží dál
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  services.envfs.enable = true;
  hardware.graphics.enable32Bit = true;
  environment.systemPackages = with pkgs; [
    mangohud
    umu-launcher
    games
    gamesDesktop
    cabextract
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      libGL
      vulkan-loader
      libxkbcommon
      alsa-lib
      libpulseaudio
      udev
      libX11
      libXcursor
      libXrandr
      libXi
      libXext
      libXinerama
      libXScrnSaver
      libGL
      openal
      SDL2
      libunwind
      flac
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-libav
    ];
  };

  environment.ldso32 = lib.mkForce "${pkgs.pkgsi686Linux.nix-ld}/libexec/nix-ld";
  environment.sessionVariables = {
    NIX_LD_i686_linux = pkgs.pkgsi686Linux.stdenv.cc.bintools.dynamicLinker;
    NIX_LD_LIBRARY_PATH_i686_linux = "${libs32}/lib:/run/opengl-driver-32/lib";
  };

  home-manager.users.stybr.programs.mangohud = {
    enable = true;
    settings = {
      horizontal = true;
      hud_compact = true;
      gpu_power = true;
      cpu_power = true;
      gpu_temp = true;
      cpu_temp = true;
      gpu_junction_temp = true;
      throttling_status = true;
      vram = true;
      ram = true;
      device_battery = "gamepad";
    };
  };

  # pridano puvodne kvuli sekani v Black Mesa, vyreseno odstranenim stybra z inputs skupiny, black mesa uz nenacita vsechny inputy a tim se sekani vyresilo
  # boot.kernelParams = [ "rcupdate.rcu_expedited=1" ];

}
