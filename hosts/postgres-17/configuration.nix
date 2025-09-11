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
    ./../../modules/pgBackup
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
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
}
