{ pkgs, ... }:

let
  affinityUrlHandler = pkgs.writeShellScript "affinity-url-handler" ''
    exec env DESKTOPINTEGRATION=1 "$HOME/AppImages/affinity.appimage" "$@"
  '';
in
{
  environment.systemPackages = [
    (pkgs.makeDesktopItem {
      name = "affinity-url-handler";
      desktopName = "Affinity URL Handler";
      exec = "${affinityUrlHandler} %u";
      noDisplay = true;
      mimeTypes = [ "x-scheme-handler/affinity" ];
    })
  ];

  xdg.mime.defaultApplications."x-scheme-handler/affinity" = "affinity-url-handler.desktop";
}
