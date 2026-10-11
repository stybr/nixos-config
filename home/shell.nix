{ ... }:

{
  programs.fish = {
    enable = true;
    generateCompletions = true;
    shellInit = ''
      set -gx EDITOR "emacsclient -c"
      set -gx SUDO_EDITOR "emacsclient -c"
      fish_add_path $HOME/.local/bin
      fish_add_path $HOME/.config/emacs/bin
      fish_vi_key_bindings
    '';
    shellAbbrs = {
      kcs = "kdeconnect-cli -n rlw-phone --share";
      low = "libreoffice --writer";
      loc = "libreoffice --calc";
      loi = "libreoffice --impress";
      lod = "libreoffice --draw";
      yda = "yt-dlp -f ba --embed-metadata --embed-thumbnail --embed-chapters -x --download-archive .archive-file";
      ydav = "yt-dlp -f b --embed-metadata --embed-thumbnail --embed-chapters -x --download-archive .archive-file";
      nrs = "sudo nixos-rebuild switch --flake /home/stybr/nixos-config";
      nfu = "sudo nix flake update --flake /home/stybr/nixos-config";
      gc = "git clone";
      gd = "git diff";
      gaa = "git add -A";
      gcm = "git commit -m";
      z = "zathura --mode=fullscreen";
      se = "sudoedit";
      ec = "emacsclient -cn";
      sst = "sudo systemctl start";
      sse = "sudo systemctl enable --now";
      ssd = "sudo systemctl disable";
      ssr = "sudo systemctl restart";
      ss = "systemctl status";
      sus = "systemctl --user status";
      sut = "systemctl --user start";
      sue = "systemctl --user enable --now";
      sud = "systemctl --user disable";
      sur = "systemctl --user restart";
      sure = "systemctl --user restart emacs";
      tp = "trash put";
      te = "trash empty";
      tea = "trash empty --all";
      cx = "chmod a+x";
      pk = "k";
      juu = "journalctl --user -u";
      jut = "journalctl --user -t";
      ju = "journalctl -u";
      cdd = "cd ~/.config/doom";
      cdn = "cd ~/nixos-config";
    };

  };

}
