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
  ];

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  myCaddy = {
    enable = true;
    hostName = "staging.rpgweave.com";
    reverseProxyAddress = "127.0.0.1:8000";
  };

  networking.hostName = "rpgweave-staging";
}
