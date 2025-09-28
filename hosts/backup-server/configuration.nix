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

  age.secrets.pg17-admin-password-file = {
    file = ../../secrets/pg17-admin-password-file.age;
    mode = "0400";
    owner = "backup";
    group = "backup";
  };

  services.postgresBackup = {
    enable = true;
    entries = [
      {
        name = "forgejo";
        host = "pg17.tailscale.rileymathews.com";
        user = "backup";
        passwordFile = config.age.secrets.pg17-admin-password-file.path;
      }
      {
        name = "gatus";
        host = "pg17.tailscale.rileymathews.com";
        user = "backup";
        passwordFile = config.age.secrets.pg17-admin-password-file.path;
      }
      {
        name = "miniflux";
        host = "pg17.tailscale.rileymathews.com";
        user = "backup";
        passwordFile = config.age.secrets.pg17-admin-password-file.path;
      }
      {
        name = "rpgweave";
        host = "pg17.tailscale.rileymathews.com";
        user = "backup";
        passwordFile = config.age.secrets.pg17-admin-password-file.path;
      }
      {
        name = "rpgweave-staging";
        host = "pg17.tailscale.rileymathews.com";
        user = "backup";
        passwordFile = config.age.secrets.pg17-admin-password-file.path;
      }
      {
        name = "mealie";
        host = "db1.tailscale.rileymathews.com";
        user = "backup";
        passwordFile = config.age.secrets.pg17-admin-password-file.path;
      }
      {
        name = "vaultwarden";
        host = "db1.tailscale.rileymathews.com";
        user = "backup";
        passwordFile = config.age.secrets.pg17-admin-password-file.path;
      }
    ];
  };
}

