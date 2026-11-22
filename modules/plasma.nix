{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.desktopManager.plasma6.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  programs.ghostty.enable = true;
  programs.mpv.enable = true;
  programs.libreoffice.enable = true;
  programs.firefox.enable = true;
}
