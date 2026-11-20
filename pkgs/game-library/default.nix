{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  rsync,
  pciutils,
  procps,
}:

stdenvNoCC.mkDerivation {
  pname = "game-library";
  version = "0.1"; # stejná jako VERSION v game_library.py

  # do balíku jen soubory aplikace (úprava default.nix pak nemění zdroj)
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./game_library.py
      ./web
    ];
  };

  nativeBuildInputs = [ makeWrapper ];

  # backend hledá web/ vedle game_library.py, takže stačí obojí zkopírovat k sobě
  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/game-library $out/bin
    cp -r game_library.py web $out/share/game-library/

    # /run/wrappers/bin první: fusermount3 musí být systémový setuid wrapper,
    # ne ten z balíku fuse3 (bez setuid by odpojení dwarfs selhalo)
    makeWrapper ${python3}/bin/python3 $out/bin/game-library-backend \
      --add-flags $out/share/game-library/game_library.py \
      --prefix PATH : /run/wrappers/bin:${
        lib.makeBinPath [
          rsync
          pciutils
          procps # pkill: zavření okna launcheru při spuštění hry
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "Controller-friendly launcher for jc141 games stored on the NUC";
    mainProgram = "game-library-backend";
    platforms = lib.platforms.linux;
  };
}
