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

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  networking.hostName = "rpgweave-staging";
}
