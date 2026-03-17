{ pkgs, ... }:
{
  programs.zellij.enable = false;

  home.packages = [
    pkgs.zellij
  ];

  xdg.configFile."zellij/config.kdl".text = builtins.readFile ./zellij.kdl;
}
