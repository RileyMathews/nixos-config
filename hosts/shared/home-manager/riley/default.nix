{ ... }:
{
  imports = [
    ../../../ds9/alacritty.nix
    ../../../ds9/dunst.nix
    ../../../ds9/hypr.nix
    ../../../ds9/opencode.nix
    ../../../ds9/rofi.nix
    ../../../ds9/waybar.nix
    ../../../ds9/wlr-which-key.nix
  ];

  home.username = "riley";
  home.homeDirectory = "/home/riley";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.file = {
    ".zshrc".text = ''
      source ~/.config/zsh/zsh-entrypoint.sh
    '';
    ".config/zsh/zsh-entrypoint.sh".source = ../../../ds9/zsh-entrypoint.sh;
    ".config/zsh/zsh-syntax-highligting-theme.sh".source = ../../../ds9/zsh-syntax-highligting-theme.sh;
    ".tmux.conf".source = ../../../ds9/tmux.conf;
  };
}
