{ lib, ... }:

{

  networking.hostName = "rlw-ziggy";

  clan.core.networking.targetHost = "root@192.168.50.232";

  services.xserver.xkb = {
    layout = lib.mkForce "cz,us";
    variant = lib.mkForce ",";
    options = lib.mkForce "grp:alt_shift_toggle";
  };

}
