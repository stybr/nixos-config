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
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "hm-bak";
    users = {
      "stybr" = import ../home/common.nix;
    };
  };

}
