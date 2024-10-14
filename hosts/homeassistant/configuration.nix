{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./../../modules/vms/basic-disk-config.nix
    ./../../modules/vms/basic-hardware-config.nix
    ./../../modules/vms/basic-config.nix
    ./../../modules/caddy-single-proxy
    ./../../modules/backup
  ];

  networking.hostName = "homeassistant";
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;

  myCaddy = {
    enable = true;
    hostName = "home.rileymathews.com";
    reverseProxyAddress = "127.0.0.1:8123";
  };

  networking.firewall.enable = false;

  services.avahi.enable = true;
}
