{ config, ... }: {

  networking.hostName = "rlw-work";
  system.stateVersion = "25.05";

  # systemd unit for automatically backup roam database to git repo
  home-manager.users.stybr.imports = [ ../../home/roam-backup.nix ];

  clan.core.networking.targetHost = "root@localhost";

  # main ssh key for GitHub and other
  clan.core.vars.generators.ssh-main = {
    prompts.id_ed25519 = {
      description = "Main SSH key for GitHub and other";
      type = "multiline";
      persist = true;
    };
    files.id_ed25519.owner = "stybr";
  };

  # ssh key for roam.git repo
  clan.core.vars.generators.ssh-roam = {
    prompts.roam_deploy = {
      description = "SSH deploy key for roam.git";
      type = "multiline";
      persist = true;
    };
    files.roam_deploy.owner = "stybr";
  };

  systemd.tmpfiles.rules = [
    "L+ /home/stybr/.ssh/id_ed25519 - - - - ${config.clan.core.vars.generators.ssh-main.files.id_ed25519.path}"
    "L+ /home/stybr/.ssh/roam_deploy - - - - ${config.clan.core.vars.generators.ssh-roam.files.roam_deploy.path}"
  ];

  fileSystems."/mnt/games" = {
    device = "rlw-nuc:/data/games";
    fsType = "nfs";
    options = [
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10s"
    ];
  };

}
