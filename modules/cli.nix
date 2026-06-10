{ pkgs, config, ... }:

{

  sops.secrets."syncthing-password" = {
    sopsFile = ../secrets/services.yaml;
    owner = "syncthing";
  };

  services.udisks2.enable = true;

  services.fwupd.enable = true;

  services.openssh.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    guiPasswordFile = config.sops.secrets."syncthing-password".path;
    settings.gui.user = "stybr";
  };

  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    age
    alsa-utils
    btop
    cdrtools
    claude-code
    cliphist
    cmake
    copilot-language-server
    cpufetch
    dmidecode
    dnsmasq
    exfatprogs
    exiftool
    fastfetch
    fd
    ffmpeg
    file
    flac
    gallery-dl
    gcc
    gdb
    gemini-cli
    gh
    git
    gnumake
    gnupg
    inxi
    just
    libinput
    libisoburn
    libtool
    lsof
    mediainfo
    mu
    ncdu
    neovim
    newsboat
    nh
    nixfmt
    nix-index
    nodejs
    ntfs3g
    nushell
    pass-wayland
    p7zip
    pkg-config
    pnpm
    prettier
    psmisc
    pulsemixer
    python3
    python3Packages.matplotlib
    python3Packages.mutagen
    hunspell
    hunspellDicts.cs_CZ
    ripgrep
    smartmontools
    sof-firmware
    sops
    sox
    spice
    ssh-to-age
    streamrip
    testdisk
    tmux
    tor
    trashy
    tree-sitter
    unrar
    unzip
    usbutils
    uv
    ventoy
    wget
    wl-clipboard
    xdg-user-dirs
    yazi
    yt-dlp
    zellij
    zsh
  ];

}
