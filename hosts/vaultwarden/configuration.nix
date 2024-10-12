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
    ./../../modules/backup
  ];

  services.vaultwarden = {
    enable = true;
    config = {
      ROCKET_PORT = "8000";
    };
  };

  myCaddy = {
    enable = true;
    hostName = "vaultwarden.rileymathews.com";
    reverseProxyAddress = "127.0.0.1:8000";
  };

  networking.hostName = "vaultwarden";

  services.backup = {
    enable = true;
    resticRepository = "s3:https://37a8e358fee81bf1f20e08b6ffe72c1d.r2.cloudflarestorage.com:/vaultwarden-restic-repository-v2";
    backupDir = "/var/lib/bitwarden_rs";
  };
}
