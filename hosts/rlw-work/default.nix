{ ... }: {
  imports = [ ./hardware-configuration.nix ];
  networking.hostName = "rlw-work";
  system.stateVersion = "25.05";

  home-manager.users.stybr.imports = [ ../../home/roam-backup.nix ];

  sops.secrets.roam_deploy = {
    sopsFile = ../../secrets/roam.yaml;
    owner = "stybr";
    mode = "0400";
    path = "/home/stybr/.ssh/roam_deploy";
  };
}
