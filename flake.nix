{

  description = "RlWoS";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dcal = {
      url = "github:AvengeMedia/dankcalendar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      clan-core,
      ...
    }@inputs:
    let

      # mkHost =
      #   {
      #     hostname,
      #     system ? "x86_64-linux",
      #     modules,
      #   }:
      #   nixpkgs.lib.nixosSystem {
      #     inherit system;
      #     specialArgs = { inherit inputs; };
      #     modules = [
      #       inputs.sops-nix.nixosModules.sops
      #       inputs.home-manager.nixosModules.home-manager
      #       inputs.disko.nixosModules.disko
      #       ./modules
      #       ./hosts/${hostname}
      #     ]
      #     ++ modules;
      #   };

      common = [
        # inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
        # inputs.disko.nixosModules.disko
        ./modules
      ];

      clan = clan-core.lib.clan {
        inherit self;
        specialArgs = { inherit inputs; };
        meta.name = "rlwos";

        machines = {

          rlw-work = {
            nixpkgs.hostPlatform = "x86_64-linux";
            imports = common ++ [
              ./hosts/rlw-work
              ./modules/intel.nix
              ./modules/android.nix
              ./modules/media.nix
              ./modules/desktop.nix
              ./modules/virtualisation.nix
              ./modules/printing.nix
              ./modules/kodi.nix
              ./modules/steam.nix
              ./modules/gaming.nix
              ./modules/retroarch.nix
              ./modules/php-legacy.nix
            ];
          };

          rlw-center = {
            nixpkgs.hostPlatform = "x86_64-linux";
            imports = common ++ [
              ./hosts/rlw-center
              ./modules/amd.nix
              ./modules/desktop.nix
              ./modules/kodi.nix
              ./modules/steam.nix
              ./modules/gaming.nix
              ./modules/retroarch.nix
            ];
          };

          rlw-nuc = {
            nixpkgs.hostPlatform = "x86_64-linux";
            imports = common ++ [
              ./hosts/rlw-nuc
              ./modules/intel.nix
            ];
          };

        };
      };

    in
    {
      inherit (clan.config) nixosConfigurations nixosModules clanInternals;
      clan = clan.config;

      devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
        packages = [ clan-core.packages.x86_64-linux.clan-cli ];
      };
    };
}
