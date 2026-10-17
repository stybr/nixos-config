{ ... }:

{
  imports = [ ./disko-config.nix ];

  networking.hostName = "rlw-nuc";

  clan.core.networking.targetHost = "root@192.168.50.214";

  zramSwap.enable = true;

}
