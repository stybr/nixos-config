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
      BitTorrent.Session.DefaultSavePath = "/data/games";
      Preferences.WebUI = {
        Username = "stybr";
        Password_PBKDF2 = "@ByteArray(3Q6brhDN2MmMtVo9hB1yzA==:+h2qIFdEz49yW3BKuVHDAKvyHF5d1vIcBcNMR997hzAmbNmlCypjC5YYK+c16bPXtW/lvSbE51hp78wE3texaw==)";
        AlternativeUIEnabled = true;
        RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
        # LocalHostAuth = false;
      };
    };
  };

  systemd.services.qbittorrent.serviceConfig.ProtectHome = lib.mkForce false;

}
