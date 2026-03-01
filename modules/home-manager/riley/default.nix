{ pkgs, config, ... }:
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
  ];

  home.username = "riley";
  home.homeDirectory = "/home/riley";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  age.secrets.github-token-file.file = ../../../secrets/github-token-file.age;
  age.secrets.forgejo-token-file.file = ../../../secrets/forgejo-token-file.age;

  home.file = {
    ".zshrc".text = ''
      source ~/.config/zsh/zsh-entrypoint.sh
      export GITHUB_TOKEN=$(cat ${config.age.secrets.github-token-file.path})
      export FORGEJO_TOKEN=$(cat ${config.age.secrets.forgejo-token-file.path})
    '';
    ".config/zsh/zsh-entrypoint.sh".source = ./zsh-entrypoint.sh;
    ".config/zsh/zsh-syntax-highligting-theme.sh".source = ./zsh-syntax-highligting-theme.sh;
    ".tmux.conf".source = ./tmux.conf;
  };

  home.packages = with pkgs; [
    pgcli
  ];
}
