{ pkgs, ... }:

{
  # random key for the LUKS container on 4TB data disk
  clan.core.vars.generators.data-disk = {
    files.key = { };
    runtimeInputs = [ pkgs.coreutils ];
    script = ''
      head -c 48 /dev/urandom | base64 -w0 > "$out"/key
    '';
  };

}
