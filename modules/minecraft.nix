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
        white-list = false;
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

      symlinks = {
        "plugins/Chunky.jar" = pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/fALzjamp/versions/MdY6JATr/Chunky-Bukkit-1.5.3.jar";
          sha512 = "43ffecc6e6a734b752da41575bbb316526c124c3f878942437d5133c377bfbd9b78bda975520dc074d7158c15dade58a444ccd0fd8d8a25d165b6fc450140422";
        };
        "plugins/AxGraves.jar" = pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/Cz6msz34/versions/UlEYAsey/AxGraves-1.32.1.jar";
          sha512 = "84e9e9e3ead5a720a3608f8fca6a1e4ef137ad0036f6af3f50fbb37f17960dcc3014825d4625e01e9b24361f3e6d3aea76d2e442f6517dd77c85f8e66d1b1d73";
        };
        "plugins/GSit.jar" = pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/GOHbQGyX/versions/gnY5Flgo/GSit-3.7.0.jar";
          sha512 = "7813fe99d2fde47e3a40538c09b87b88b6101c27fb4f3305e0fd9bf806809c37e4e67c726f96596caca79785cdd7aa8d8ae724b211535775db21e602f57993d5";
        };
        "plugins/HuskHomes.jar" = pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/J6U9o3JG/versions/eXHdkjXf/HuskHomes-Paper-4.11-9ed80cc.jar";
          sha512 = "6af0a47e25d53b534362c8fd8598772fcbd19d2ba1e66571b054e4c9bde64188f4b1bda9fc44fc69d9fab11220a5add6e5195fbdee0f591e3af8e5d9b939ed7d";
        };
      };

    };

  };

}
