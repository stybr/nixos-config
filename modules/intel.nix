{ pkgs, ... }:

{

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
      intel-compute-runtime
    ];
  };

  environment.systemPackages = with pkgs; [
    intel-gpu-tools
  ];

  environment.sessionVariables.OCL_ICD_VENDORS = "/run/opengl-driver/etc/OpenCL/vendors";

}
