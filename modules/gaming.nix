{ pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    heroic
    gamescope
    umu-launcher
    wine-staging
  ];

}
