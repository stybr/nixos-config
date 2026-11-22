{ config, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.amdgpu.overdrive.enable = true;

  services.lact.enable = true;

  boot.extraModulePackages = [ config.boot.kernelPackages.zenergy ];
  boot.kernelModules = [ "zenergy" ];

}
