{ pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.amdgpu.overdrive.enable = true;

  services.lact.enable = true;

  hardware.amdgpu.opencl.enable = true;
  environment.sessionVariables.OCL_ICD_VENDORS = "/run/opengl-driver/etc/OpenCL/vendors";

}
