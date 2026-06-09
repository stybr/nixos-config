{ ... }:

{

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowInsecurePredicate = _: true;
  nixpkgs.config.allowUnfree = true;

}
