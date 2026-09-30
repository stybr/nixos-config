{ pkgs, ... }:

{

  services.printing = {
    enable = true;
    drivers = [
      pkgs.samsung-unified-linux-driver
      pkgs.samsung-unified-linux-driver_1_00_37
      pkgs.splix
    ];
  };

  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
  };

  users.users.stybr.extraGroups = [
    "lp"
    "scanner"
  ];

  environment.systemPackages = with pkgs; [
    simple-scan
  ];

}
