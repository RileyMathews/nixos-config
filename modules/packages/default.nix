{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    neovim
    git
    tailscale
    stow
    gcc
    dunst
    sxhkd
    starship
    direnv
    zoxide
    tmux
    i3
    i3status
    alacritty
    rofi
    librewolf
    brightnessctl
    awesome
    unzip
    fzf
  ];
}
