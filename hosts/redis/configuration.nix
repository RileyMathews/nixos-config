{
  config,
  modulesPath,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:
{
  imports = [
    ./../../modules/vms/basic-disk-config.nix
    ./../../modules/vms/basic-hardware-config.nix
    ./../../modules/vms/basic-config.nix
    ./../../modules/tailscale
    ./../../modules/dns
  ];
  networking.hostName = "redis";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  services.redis.servers."main-redis" = {
    enable = true;
    port = 6379;
  };
  networking.firewall.allowedTCPPorts = [6379];
  services.cloudflare-dns = {
    enable = true;
    domains = ["redis8.tailscale.rileymathews.com"];
  };
  # redis usage...
  # 1 RPG Weave - not migrated yet
  # 2 RPG Weave Staging - not migrated yet
  # 3 Immich
  # 4 Paperless
}
