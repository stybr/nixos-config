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

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "hm-bak";
    users = {
      "stybr" = ../home/common.nix;
    };
  };

}
