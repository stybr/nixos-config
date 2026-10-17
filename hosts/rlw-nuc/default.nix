{ ... }:

{
  imports = [ ./disko-config.nix ];

  networking.hostName = "rlw-nuc";

  zramSwap.enable = true;

}
