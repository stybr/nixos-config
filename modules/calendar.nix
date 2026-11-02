{ config, pkgs, ... }:

{

  clan.core.vars.generators.radicale = {
    prompts.login = {
      description = "Radicale login";
      type = "hidden";
    };
    files.htpasswd.owner = "radicale";
    runtimeInputs = [ pkgs.apacheHttpd ];
    script = ''
      htpasswd -ciB "$out"/htpasswd stybr < "$prompts"/login
    '';

  };

  services.radicale = {
    enable = true;
    settings = {
      server.hosts = [ "0.0.0.0:5232" ];
      auth = {
        type = "htpasswd";
        htpasswd_filename = config.clan.core.vars.generators.radicale.files.htpasswd.path;
        htpasswd_encryption = "bcrypt";
      };
    };

  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 5232 ];

}
