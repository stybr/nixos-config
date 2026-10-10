{
  config,
  lib,
  pkgs,
  ...
}:

{

  # services.deluge = {
  #   enable = true;
  #   web.enable = true;
  #   user = "stybr";
  #   group = "users";
  #   dataDir = "/home/stybr/.config/deluge";
  # };

  services.qbittorrent = {
    enable = true;
    openFirewall = true;
    webuiPort = 8080;
    user = "stybr";
    group = "users";
    serverConfig = {
      Preferences.WebUI = {
        Username = "stybr";
        Password_PBKDF2 = "@ByteArray(goFFe0Lzqq1s2hkHr1njtA==:iaLpirCE3kQr47TcYkzKO322YPuMgVN247a6J/W/0aKMGc9fVdKrGeG9xZvgKAYri3hDaTaTCsZVDwPOCqTGFw==)";
        AlternativeUIEnabled = true;
        RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
        # LocalHostAuth = false;
      };
    };
  };

  systemd.services.qbittorrent.serviceConfig.ProtectHome = lib.mkForce false;

}
