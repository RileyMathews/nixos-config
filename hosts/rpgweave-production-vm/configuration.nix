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

  networking.firewall.allowedTCPPorts = [8000];

  networking.hostName = "rpgweave-production";
}
