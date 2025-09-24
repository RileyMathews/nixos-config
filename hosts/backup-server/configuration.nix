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
    ./../../modules/tailscale
    ./../../modules/postgres-backup
  ];
  networking.hostName = "backup-server";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  services.postgresBackup = {
    enable = true;
    entries = [
      {
        name = "test";
        host = "test.test.com";
        user = "testuser";
        passwordFile = ./../../README.md;
      }
    ];
  };
}

