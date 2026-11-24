{ pkgs, lib, ... }:

{

  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: [
        pkgs.gnutls
        # AppImages like Affinity put /usr/lib into LD_LIBRARY_PATH, which
        # breaks every browser they open. Drop it before opening links.
        (lib.hiPrio (
          pkgs.writeShellScriptBin "xdg-open" ''
            unset LD_LIBRARY_PATH
            exec /run/current-system/sw/bin/xdg-open "$@"
          ''
        ))
      ];
    };
  };

  environment.systemPackages = [ pkgs.gearlever ];

}
