{
  config,
  lib,
  pkgs,
  ...
}:

{

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "stybr";
  };

  systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce false;

  services.navidrome = {
    enable = true;
    openFirewall = true;
    settings = {
      EnableSharing = true;
      MusicFolder = "/home/stybr/Music/tidarr";
      Address = "0.0.0.0";
      Port = 4533;
    };
  };

  environment.systemPackages = with pkgs; [
    mediaelch
    jellyfin
    jellyfin-web
  ];

}
