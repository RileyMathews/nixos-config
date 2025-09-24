{
  modulesPath,
  lib,
  pkgs,
  config,
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

  age.secrets.forgejo-database-password = {
    file = ../../secrets/forgejo-database-password.age;
    owner = "backup";
    group = "backup";
    mode = "0400";
  };
  age.secrets.gatus-database-password = {
    file = ../../secrets/gatus-database-password.age;
    owner = "backup";
    group = "backup";
    mode = "0400";
  };

  services.postgresBackup = {
    enable = true;
    entries = [
      {
        name = "forgejo";
        host = "pg17.tailscale.rileymathews.com";
        user = "forgejo";
        passwordFile = config.age.secrets.forgejo-database-password.path;
      }
      {
        name = "gatus";
        host = "pg17.tailscale.rileymathews.com";
        user = "gatus";
        passwordFile = config.age.secrets.gatus-database-password.path;
      }
    ];
  };
}

