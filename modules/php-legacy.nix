{ pkgs, ... }:

{
  services.httpd = {
    enable = true;
    enablePHP = true;
    virtualHosts."localhost" = {
      documentRoot = "/home/stybr/Documents/web";
    };
  };

  users.users.wwwrun.extraGroups = [ "users" ];

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

}
