{ ... }: {
  imports = [ ./hardware-configuration.nix ];
  networking.hostName = "rlw-work";
  system.stateVersion = "25.05";

  # systemd unit for automatically backup roam database to git repo
  home-manager.users.stybr.imports = [ ../../home/roam-backup.nix ];

  # ssh key for roam.git repo
  sops.secrets.roam_deploy = {
    sopsFile = ../../secrets/roam.yaml;
    owner = "stybr";
    mode = "0400";
    path = "/home/stybr/.ssh/roam_deploy";
  };

  # main ssh key for github and other
  sops.secrets.id_ed25519 = {
    sopsFile = ../../secrets/ssh.yaml;
    owner = "stybr";
    mode = "0400";
    path = "/home/stybr/.ssh/id_ed25519";
  };

}
