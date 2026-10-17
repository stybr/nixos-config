{ ... }:

{
  users.groups.media = { };

  users.users.stybr.extraGroups = [ "media" ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  users.users.jellyfin.extraGroups = [
    "media"
    "render"
    "video"
  ];

}
