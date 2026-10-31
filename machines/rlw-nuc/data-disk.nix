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

  fileSystems."/data/games" = {
    device = "/dev/mapper/data";
    fsType = "btrfs";
    options = [
      "subvol=@games"
      "noatime"
      "nofail"
    ];
  };

  fileSystems."/data/books" = {
    device = "/dev/mapper/data";
    fsType = "btrfs";
    options = [
      "subvol=@books"
      "noatime"
      "nofail"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /data/music 2770 root media - -"
    "d /data/games 2770 root media - -"
    "d /data/books 2770 root media - -"
  ];

  services.nfs.server = {
    enable = true;
    exports = ''
      /data/games 192.168.50.59(ro,all_squash,anonuid=65534,anongid=2000,no_subtree_check) 100.98.147.68(rw,all_squash,anonuid=1000,anongid=2000,no_subtree_check)
    '';
  };

  systemd.services.nfs-server.unitConfig.RequiresMountsFor = "/data/games";
  networking.firewall.allowedTCPPorts = [ 2049 ];

}
