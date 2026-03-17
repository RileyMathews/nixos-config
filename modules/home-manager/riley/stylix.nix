{ pkgs, ... }:
{
  stylix.enable = true;
  stylix.polarity = "dark";
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

  # enabling stylix for librewolf requires
  # sometimes stomping on all extensions settings
  stylix.targets.librewolf.enable = false;
  stylix.targets.alacritty.colors.enable = true;
  stylix.targets.ghostty.colors.enable = true;
  stylix.targets.nushell.colors.enable = true;

  stylix.fonts = {
    monospace = {
      package = pkgs.nerd-fonts.hack;
      name = "Hack Nerd Font";
    };

    sizes.terminal = 12;
  };
}
