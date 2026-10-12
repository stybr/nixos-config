{ pkgs, inputs, ... }:

{

  users.users.stybr = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "video"
      "networkmanager"
      "docker"
      "adbusers"
      "kvm"
      "libvirtd"
    ];
    homeMode = "0711";
    packages = with pkgs; [
      tree
    ];
  };

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN0LkhPdYXtN16+2ZZGLEjomNCHc5UbmokZISc5Qo2r9 stybr@rlw-work"
    ];

  };

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "hm-bak";
    users = {
      "stybr" = ../home/common.nix;
    };
  };

}
