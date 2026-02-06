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

  age.secrets.immich-password-file = {
    file =  ../../secrets/immich-password-file.age;
    mode = "0400";
    group = "backup";
    owner = "backup";
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
        host = "pg17.tailscale.rileymathews.com";
        user = "backup";
        passwordFile = config.age.secrets.pg17-admin-password-file.path;
      }
      {
        name = "vaultwarden";
        host = "pg17.tailscale.rileymathews.com";
        user = "backup";
        passwordFile = config.age.secrets.pg17-admin-password-file.path;
      }
      {
        name = "paperless";
        host = "pg17.tailscale.rileymathews.com";
        user = "backup";
        passwordFile = config.age.secrets.pg17-admin-password-file.path;
      }
      {
        name = "homebox";
        host = "pg17.tailscale.rileymathews.com";
        user = "backup";
        passwordFile = config.age.secrets.pg17-admin-password-file.path;
      }
      {
        name = "vikunja";
        host = "pg17.tailscale.rileymathews.com";
        user = "backup";
        passwordFile = config.age.secrets.pg17-admin-password-file.path;
      }
      {
        name = "buffer";
        host = "pg17.tailscale.rileymathews.com";
        user = "backup";
        passwordFile = config.age.secrets.pg17-admin-password-file.path;
      }
      {
        name = "immich";
        host = "immichdb";
        user = "immich";
        passwordFile = config.age.secrets.immich-password-file.path;
      }
    ];
  };
}

