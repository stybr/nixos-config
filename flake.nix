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

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      mkHost =
        {
          hostname,
          system ? "x86_64-linux",
          modules,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            inputs.home-manager.nixosModules.home-manager
            inputs.disko.nixosModules.disko
            ./modules
            ./hosts/${hostname}
          ]
          ++ modules;
        };
    in
    {
      nixosConfigurations = {

        rlw-work = mkHost {
          hostname = "rlw-work";
          modules = [
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

        rlw-center = mkHost {
          hostname = "rlw-center";
          modules = [
            ./modules/amd.nix
            ./modules/desktop.nix
            ./modules/kodi.nix
            ./modules/steam.nix
            ./modules/gaming.nix
            ./modules/retroarch.nix
          ];
        };

        rlw-nuc = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            inputs.home-manager.nixosModules.home-manager
            ./hosts/rlw-nuc
            ./modules
            ./modules/intel.nix
          ];
        };

      };
    };

}
