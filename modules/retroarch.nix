{ config, pkgs, lib, ...}:

{

  environment.systemPackages = with pkgs; [
    (retroarch.withCores (cores: with cores; [
      mgba
      atari800
    ]))
  ];

}
