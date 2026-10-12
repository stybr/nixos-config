{
  config,
  ...
}:

{

  sops.secrets."syncthing-password" = {
    sopsFile = ../secrets/services.yaml;
    owner = "stybr";
  };

  clan.core.vars.generators.syncthing = {
    prompts.password = {
      description = "Syncthing GUI password";
      type = "hidden";
      persist = true;
    };
    files.password.owner = "stybr";
  };

  services.syncthing = {

    enable = true;
    user = "stybr";
    dataDir = "/home/stybr";
    openDefaultPorts = true;
    guiPasswordFile = config.sops.secrets."syncthing-password".path;

    settings = {

      gui.user = "stybr";

      devices.graphene = {
        id = "SUGMYPW-TQJ35UI-PW6USNA-XETKLUD-ZU6FYBT-L5OVV55-LJIIT4I-HERDPAB";
      };

      folders.roam = {
        path = "~/Documents/roam";
        id = "roam";
        devices = [ "graphene" ];
        type = "sendonly";
      };

      folders.slob = {
        path = "~/Documents/slob";
        id = "slob";
        devices = [ "graphene" ];
        type = "sendonly";
      };

      folders.epub = {
        path = "~/Documents/epub";
        id = "epub";
        devices = [ "graphene" ];
        type = "sendonly";
      };

    };

  };

}
