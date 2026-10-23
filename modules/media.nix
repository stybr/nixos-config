{ config, pkgs, ... }:

{
  users.groups.media.gid = 2000;

  users.users.stybr.extraGroups = [ "media" ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  services.navidrome = {
    enable = true;
    openFirewall = true;
    settings = {
      MusicFolder = "/data/music";
      Port = 4533;
      Address = "0.0.0.0";
    };

  };

  users.users.navidrome.extraGroups = [ "media" ];

  users.users.jellyfin.extraGroups = [
    "media"
    "render"
    "video"
  ];

  clan.core.vars.generators.tidarr = {
    prompts.admin-password = {
      description = "Admin password for Tidarr";
      type = "hidden";
    };
    files.env = { };
    runtimeInputs = [ pkgs.coreutils ];
    script = ''
      printf 'ADMIN_PASSWORD=%s\n' "$(cat "$prompts"/admin-password)" > "$out"/env
    '';
  };

  virtualisation.oci-containers.containers.tidarr = {
    image = "docker.io/cstaelen/tidarr";
    ports = [ "8484:8484" ];
    environment = {
      PUID = "1000";
      PGID = "2000";
    };
    environmentFiles = [ config.clan.core.vars.generators.tidarr.files.env.path ];
    volumes = [
      "/data/music:/music"
      "/var/lib/tidarr:/shared"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/tidarr 0750 stybr media - -"
  ];

  systemd.services.podman-tidarr = {
    requires = [ "data-music.mount" ];
    after = [ "data-music.mount" ];
  };

  systemd.services.navidrome = {
    requires = [ "data-music.mount" ];
    after = [ "data-music.mount" ];
  };

  networking.firewall.allowedTCPPorts = [ 8484 ];

}
