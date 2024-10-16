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

  networking.hostName = "pgadmin";

  services.pgadmin.enable = true;
  services.pgadmin.initialEmail = "dev@rileymathews.com";
  services.pgadmin.initialPasswordFile = "/home/riley/pgpass";

  myCaddy = {
    enable = true;
    hostName = "pgadmin.rileymathews.com";
    reverseProxyAddress = "127.0.0.1:5050";
  };
}
