{ lib, inputs, ... }:

{
  _module.args.pkgs = lib.mkForce inputs.unstablePkgs;

  imports = [
    ../../../modules/home-manager/riley
    inputs.agenix.homeManagerModules.default
    inputs.stylix.homeModules.stylix
  ];

  riley.browser = "librewolf";
  riley.altBrowser = "google-chrome-stable";
  riley.opencode.profile = "personal";
  riley.opencode.superpowers.enable = false;

  home.file.".config/hypr/monitors.conf".source = ./hypr/monitors.conf;
}
