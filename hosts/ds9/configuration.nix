{ pkgs, ... }:
{
  home.username = "riley";
  home.homeDirectory = "/home/riley";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    fastfetch
  ];
}
