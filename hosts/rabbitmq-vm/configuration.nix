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

  services.rabbitmq.enable = true;
  services.rabbitmq.listenAddress = "0.0.0.0";

  networking.firewall.allowedTCPPorts = [5672];

  networking.hostName = "rabbitmq";
}
