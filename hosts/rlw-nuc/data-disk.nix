{ config, pkgs, ... }:

{
  # random key for the LUKS container on 4TB data disk
  clan.core.vars.generators.data-disk = {
    files.key = { };
    runtimeInputs = [ pkgs.coreutils ];
    script = ''
      head -c 48 /dev/urandom | base64 -w0 > "$out"/key
    '';
  };

  environment.etc.crypttab.text = ''
    data UUID=62519efb-0464-4dfd-ad4c-3bcfb993b372 ${config.clan.core.vars.generators.data-disk.files.key.path} luks,discard,nofail
  '';

  fileSystems."/data/music" = {
    device = "/dev/mapper/data";
    fsType = "btrfs";
    options = [
      "subvol=@music"
      "noatime"
      "nofail"
    ];
  };

}
