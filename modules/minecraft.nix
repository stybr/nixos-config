{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];

  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = true;

    servers.paper = {
      enable = true;
      package = pkgs.paperServers.paper-26_3;
      jvmOpts = "-Xms2G -Xmx4G";

      serverProperties = {
        server-port = 25565;
        online-mode = false;
        max-players = 2;
        difficulty = "normal";
        motd = "rlw-nuc";
      };

      operators.stybr = {
        uuid = "10d91098-1395-312f-ae97-e6809c843fc5";
        level = 4;
        bypassesPlayerLimit = true;
      };
    };
  };

}
