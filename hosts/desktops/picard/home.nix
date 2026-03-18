{ lib, inputs, ... }:

{
  _module.args.pkgs = lib.mkForce inputs.unstablePkgs;

  imports = [
    ../../../modules/home-manager/riley
    inputs.pr-tracker.homeManagerModules.default
    inputs.agenix.homeManagerModules.default
    inputs.stylix.homeModules.stylix
  ];

  riley.browser = "google-chrome-stable";
  riley.opencode.profile = "work";

  home.file.".config/hypr/monitors.conf".source = ./hypr/monitors.conf;

  services.pr-tracker-sync.enable = true;
}
