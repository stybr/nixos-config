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

}
