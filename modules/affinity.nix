{
  inputs,
  pkgs,
  ...
}:

{
  nix.settings = {
    extra-substituters = [ "https://cache.garnix.io" ];
    extra-trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
  };

  environment.systemPackages = [
    inputs.affinity-nix.packages.${pkgs.stdenv.hostPlatform.system}.v3
  ];
}
