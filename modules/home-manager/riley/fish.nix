{ config, lib, pkgs, ... }:
{
  config = {
    xdg.configFile."fish/config.fish".text = builtins.readFile ./config.fish;
    xdg.configFile."fish/functions/fish_user_key_bindings.fish".text = builtins.readFile ./fish_user_key_bindings.fish;
  };
}
