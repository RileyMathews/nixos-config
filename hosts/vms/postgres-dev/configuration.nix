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
    ./../../../modules/tailscale
    ./../../../modules/dns
  ];
  networking.hostName = "postgres-dev";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    enableTCPIP = true;
    authentication = ''
      local all pgadmin peer
      local all all trust
      host all all 0.0.0.0/0 md5
    '';
    settings = {
      timezone = "UTC";
      log_timezone = "UTC";
    };
  };
  networking.firewall.allowedTCPPorts = [5432];
  services.cloudflare-dns = {
    enable = true;
    domains = ["pgdev.tailscale.rileymathews.com"];
  };
}
