{ ... }: {
  imports = [ ./hardware-configuration.nix ];
  networking.hostName = "rlw-work";
  system.stateVersion = "25.05";
}
