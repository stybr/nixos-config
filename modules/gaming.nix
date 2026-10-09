{ pkgs, lib, ... }:

let
  # 32bitové knihovny pro staré hry (např. Postal 2)
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
in
{

  programs.gamescope.enable = true;
  programs.gamemode.enable = true;
  services.envfs.enable = true;
  hardware.graphics.enable32Bit = true;
  environment.systemPackages = with pkgs; [
    heroic
    mangohud
    umu-launcher
    wineWow64Packages.stagingFull
    prismlauncher
    dosbox-x
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
    ];
  };

  environment.ldso32 = lib.mkForce "${pkgs.pkgsi686Linux.nix-ld}/libexec/nix-ld";
  environment.sessionVariables = {
    NIX_LD_i686_linux = pkgs.pkgsi686Linux.stdenv.cc.bintools.dynamicLinker;
    NIX_LD_LIBRARY_PATH_i686_linux = "${libs32}/lib:/run/opengl-driver-32/lib";
  };

}
