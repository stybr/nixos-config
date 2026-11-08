{
  inputs,
  ...
}:

{

  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
  ];

  services.flatpak = {
    enable = true;
    packages = [
      "org.vinegarhq.Sober"
    ];

    overrides.settings = {
      "org.vinegarhq.Sober".Context.devices = [ "input" ];
    };

  };

}
