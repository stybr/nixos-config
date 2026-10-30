{ ... }:

{
  imports = [
    ./data-disk.nix
  ];

  networking.hostName = "rlw-nuc";

  # clan.core.networking.targetHost = "root@192.168.50.214";
  clan.core.networking.targetHost = "root@rlw-nuc";

  zramSwap.enable = true;

  services.openssh.settings.KbdInteractiveAuthentication = false;

}
