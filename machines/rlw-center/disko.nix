{
  config,
  lib,
  pkgs,
  ...
}:

{

  disko.devices.disk = {
    main = {
      device = "/dev/disk/by-id/...";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00";
            size = "512M";
            content = {
              type = "filesystem";
              format = "vfat";

            };

          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              content = {
                type = "btrfs";
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";

                  };
                };

              };

            };

          };
        };

      };

    };

  };

}
