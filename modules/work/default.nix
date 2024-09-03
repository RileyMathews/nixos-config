{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    slack
    zoom-us
  ];
  sops.secrets."kolide_enrollment_secret" = {};
  sops.secrets."work_internal_ssl_certificate" = {};

  services.kolide-launcher.enable = true;
  environment.etc."kolide-k2/secret" = {
    mode = "0600";
    source = config.sops.secrets."kolide_enrollment_secret".path;
  };
  
  # TODO: figure out a way to get this working through sops or other secrets method?
  security.pki.certificateFiles = [/home/riley/.secrets/work_ssl_cert];
}
