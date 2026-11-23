{
  config,
  lib,
  pkgs,
  ...
}:

{

  imports = [ ./appimage.nix ];

  services.desktopManager.plasma6.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  programs.firefox.enable = true;

}
