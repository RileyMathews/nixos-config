{ pkgs, ... }:
{
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  xdg.enable = true;
  xdg.configFile."opencode/opencode.json".text = ''
    {
      "plugin": ["@simonwjackson/opencode-direnv"]
    }
  '';

  home.packages = with pkgs; [
  ];
}
