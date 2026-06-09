{ config, pkgs, lib, ...}:

{

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };


}
