{ pkgs, ... }:

let
  # Runs the AppImage's Wine directly, skipping its AppRun, which runs
  # `wineserver -k` and would kill the Affinity waiting for the login.
  affinityForwardUrl = pkgs.writeShellScript "affinity-forward-url" ''
    export WINEPREFIX="$HOME/.affinity-appimage-wineprefix"
    export WINEARCH=win64
    export WINEDEBUG=-all
    export LD_LIBRARY_PATH="$APPDIR/usr/lib/wine/x86_64-unix:$APPDIR/usr/lib:/usr/lib:/usr/lib32:$APPDIR/usr/lib32"
    export WINEDLLPATH="$APPDIR/usr/lib/wine/x86_64-windows:$APPDIR/usr/lib/wine/i386-windows"
    export WINESERVER="$APPDIR/usr/bin/wineserver"
    export WINELOADER="$APPDIR/usr/bin/wine"
    cd "$WINEPREFIX/drive_c"
    exec "$APPDIR/usr/bin/wine" 'C:\Program Files\Affinity\Affinity.exe' "$AFFINITY_URL"
  '';

  affinityUrlHandler = pkgs.writeShellScript "affinity-url-handler" ''
    export AFFINITY_URL="$1"
    export APPIMAGE_DEBUG_EXEC=${affinityForwardUrl}
    exec "$HOME/AppImages/affinity.appimage"
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
