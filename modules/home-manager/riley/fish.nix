{ config, lib, pkgs, ... }:
{
  options.riley.fish.package.enable = lib.mkEnableOption "install fish from Home Manager" // {
    default = true;
  };

  config = {
    home.packages = lib.optional config.riley.fish.package.enable pkgs.fish;
    xdg.configFile."fish/config.fish".text = builtins.readFile ./config.fish;
    xdg.configFile."fish/functions/fish_user_key_bindings.fish".text = builtins.readFile ./fish_user_key_bindings.fish;
  };
}
