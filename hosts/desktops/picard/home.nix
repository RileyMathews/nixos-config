{ lib, inputs, ... }:

{
  # _module.args.pkgs = lib.mkForce inputs.unstablePkgs;
  #
  # imports = [
  #   ../../../modules/home-manager/riley
  #   inputs.agenix.homeManagerModules.default
  #   inputs.stylix.homeModules.stylix
  # ];
  #
  # riley.browser = "google-chrome-stable";
  # riley.altBrowser = "librewolf";
  # riley.opencode.profile = "work";
  #
  # home.file.".config/hypr/monitors.conf".source = ./hypr/monitors.conf;
}
