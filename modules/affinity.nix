{
  inputs,
  pkgs,
  ...
}:

let
  affinityPkgs = import inputs.affinity-nix.inputs.nixpkgs {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
    overlays = [ inputs.affinity-nix.overlays.default ];
  };
in
{
  nix.settings = {
    extra-substituters = [ "https://cache.forall.systems" ];
    extra-trusted-public-keys = [ "cache.forall.systems:5PmD7QO4MSF8YgyRZtkSGXRDo96H3bybIf2SsQh8ScI=" ];
  };

  environment.systemPackages = [
    affinityPkgs.affinity-v3
  ];
}
