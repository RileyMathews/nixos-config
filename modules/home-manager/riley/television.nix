{ pkgs, inputs, ... }:
{
  home.packages = [
    inputs.television.packages."${pkgs.system}".default
  ];

  xdg.configFile = {
    "television/config.toml".source = ./television/config.toml;
    "television/cable".source = ./television/cable;
  };
}
