{ pkgs, config, lib, ... }:
{
  imports = [
    ./alacritty.nix
    ./dunst.nix
    ./hypr.nix
    ./opencode.nix
    ./rofi.nix
    ./waybar.nix
    ./wlr-which-key.nix
    ./scripts.nix
    ./ghostty.nix
    ./worktrunk.nix
    ./direnv.nix
    ./openpeon.nix
  ];

  options.riley.browser = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = "librewolf";
    description = "Default browser command for Riley's shell environment on this host.";
  };

  options.riley.opencode.profile = lib.mkOption {
    type = lib.types.enum [
      "personal"
      "work"
    ];
    default = "personal";
    description = "OpenCode model profile for Riley's agents on this host.";
  };

  options.riley.opencode.superpowers.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Superpowers plugin and skill pack for OpenCode.";
  };

  config = {
    home.username = "riley";
    home.homeDirectory = "/home/riley";

    home.stateVersion = "25.11";

    programs.home-manager.enable = true;

    age.secrets.github-token-file.file = ../../../secrets/github-token-file.age;
    age.secrets.forgejo-token-file.file = ../../../secrets/forgejo-token-file.age;

    home.file = {
      ".zshrc".text = ''
        export GITHUB_TOKEN=$(cat ${config.age.secrets.github-token-file.path})
        export FORGEJO_TOKEN=$(cat ${config.age.secrets.forgejo-token-file.path})
        # forgejo access token specifically for mcp server
        export FORGEJO_ACCESS_TOKEN=$(cat ${config.age.secrets.forgejo-token-file.path})
        export BROWSER=${config.riley.browser};
        export GH_BROWSER=${config.riley.browser};
        source ~/.config/zsh/zsh-entrypoint.sh
      '';
      ".config/zsh/zsh-entrypoint.sh".source = ./zsh-entrypoint.sh;
      ".config/zsh/zsh-syntax-highligting-theme.sh".source = ./zsh-syntax-highligting-theme.sh;
      ".tmux.conf".source = ./tmux.conf;
    };

    home.packages = with pkgs; [
      pgcli
    ];
  };
}
