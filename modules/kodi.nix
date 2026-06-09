{ config, pkgs, lib, ...}:

{

  environment.systemPackages = [

    (pkgs.kodi-wayland.withPackages (kodiPkgs: with kodiPkgs; [
      jellyfin
    ]))

  ];

}
