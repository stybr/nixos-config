{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./shell.nix
  ];

  home.username = "stybr";
  home.homeDirectory = "/home/stybr";
  home.stateVersion = "25.05";

  services.ssh-agent.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*".AddKeysToAgent = "yes";
      "github.com" = {
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = "yes";
      };
    };
  };

  services.udiskie = {
    enable = true;
  };

  programs.beets = {
    enable = true;
    settings = {
      directory = "~/Music/beets";
      library = "~/Music/beets/library.db";
      import = {
        copy = true;
      };
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Antonín Štýbr";
        email = "antonin@stybr.com";
      };
      init.defaultBranch = "main";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
    };
  };

  programs.vdirsyncer = {
    enable = true;
  };

}
