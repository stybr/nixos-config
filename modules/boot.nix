{ pkgs, ... }:

{

  boot = {

    kernelParams = [ 
      "quiet"
      "splash" 
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
      "i2c_designware.polling_mode=1"
    ];

    initrd = {
      systemd.enable = true;
      verbose = false;
    };

    consoleLogLevel = 3;

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    plymouth = {
      enable = true;
      theme = "rings";
      themePackages = with pkgs; [
        (adi1090x-plymouth-themes.override {
	  selected_themes = [ "rings" ];
	})
      ];
    };

  };

}
