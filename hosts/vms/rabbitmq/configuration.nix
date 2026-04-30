{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./../../../modules/vms/basic-disk-config.nix
    ./../../../modules/vms/basic-hardware-config.nix
    ./../../../modules/vms/basic-config.nix
    ./../../../modules/dns
    ./../../../modules/tailscale
  ];
  networking.hostName = "rabbitmq";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;

  services.rabbitmq = {
    enable = true;
    listenAddress = "0.0.0.0";
  };
  networking.firewall.allowedTCPPorts = [5672];

  services.cloudflare-dns = {
    enable = true;
    domains = ["rabbitmq.tailscale.rileymathews.com"];
  };
}
