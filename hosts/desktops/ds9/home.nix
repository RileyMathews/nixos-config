{ ... }:
{
  imports = [
    ../../../modules/home-manager/riley
  ];

  riley.opencode.profile = "personal";
  riley.opencode.superpowers.enable = true;

  home.file.".local/hypr/10-monitors.conf".source = ./hypr/10-monitors.conf;
}
