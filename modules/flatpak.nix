{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.flatpak = {
    enable = true;
    packages = [
      "org.vinegarhq.Sober"
    ];

  };

}
