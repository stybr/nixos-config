{ pkgs, ... }:

{

  virtualisation.docker = {
    enable = true;
  };

  virtualisation.spiceUSBRedirection.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      vhostUserPackages = with pkgs; [ virtiofsd ];
      swtpm.enable = true;
    };
  };

  programs.virt-manager.enable = true;

}
