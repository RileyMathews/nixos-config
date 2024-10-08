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
  ];
  services.redis.servers."".enable = true;
  services.redis.servers."".bind = "0.0.0.0";
  services.redis.servers."".openFirewall = true;
  services.redis.servers."".extraParams = ["--protected-mode no"];

  networking.hostName = "redis";
}
