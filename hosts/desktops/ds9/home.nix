{ ... }:
{
  imports = [
    ../../../modules/home-manager/riley
  ];

  riley.opencode.profile = "personal";

  home.file.".local/hypr/10-monitors.conf".source = ./hypr/10-monitors.conf;
}
