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
    ./../../modules/tailscale/default.nix
  ];
  networking.hostName = "pg17";

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
  myTailscale.enable = true;
  networking.firewall.allowedTCPPorts = [5432];
}
