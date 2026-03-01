{ ... }:
{
  imports = [
    ../../modules/home-manager/riley
  ];

  home.file.".local/hypr/10-monitors.conf".source = ./hypr/10-monitors.conf;
}
