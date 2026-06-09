{ lib, ... }:

{

  time.timeZone = "Europe/Prague";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkForce "us";
    useXkbConfig = true;
  };

  services.xserver.xkb = {
    layout = "us";
    options = "caps:escape_shifted_capslock";
  };

}
