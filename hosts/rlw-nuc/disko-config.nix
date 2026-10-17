{ config, ... }:

{

  clan.core.vars.generators.luks = {
    prompts.passphrase = {
      description = "LUKS passphrase for rlw-nuc system disk";
      type = "hidden";
      persist = true;
    };
    files.passphrase.neededFor = "partitioning";
  };

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B7380464675";
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

        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            passwordFile = config.clan.core.vars.generators.luks.files.passphrase.path;
            settings.allowDiscards = true;
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
  };

}
