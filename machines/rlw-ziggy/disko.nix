{ ... }:

{

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/ata-KINGSTON_SA400S37480G_50026B7380730BB8";
    content = {
      type = "gpt";
      partitions = {

        ESP = {
          type = "EF00";
          size = "1G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "/@" = {
                mountpoint = "/";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/@nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/@log" = {
                mountpoint = "/var/log";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/@swap" = {
                mountpoint = "/.swapvol";
                swap.swapfile.size = "8G";
              };
            };
          };
        };

      };
    };
  };

}
