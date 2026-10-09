{ pkgs, ... }:

{

  virtualisation.docker = {
    enable = true;
  };

  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
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
