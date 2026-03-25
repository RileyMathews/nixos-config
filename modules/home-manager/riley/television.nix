{ pkgs, inputs, ... }:
{
  xdg.configFile = {
    "television/config.toml".source = ./television/config.toml;
    "television/cable".source = ./television/cable;
  };
}
