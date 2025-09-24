{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.postgresBackup;

  configFile = pkgs.writeText "myservice-config.json" (builtins.toJSON cfg.entries);
  
  backupScript = pkgs.writeShellScript "backup-script" (builtins.readFile ./backup.sh);
in
{
  options.services.postgresBackup = {
    enable = mkEnableOption "postgres backup";

    entries = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "database name";
          };
          host = mkOption {
            type = types.str;
            description = "the hostname of the database";
          };
          user = mkOption {
            type = types.str;
            description = "the database user to connect as";
          };
          passwordFile = mkOption {
            type = types.path;
            description = "the path to the file containing this database user's password";
          };
        };
      });
      default = [];
      description = "list of databases to backup";
    };
  };

  config = mkIf cfg.enable {
    users.users."backup" = {
      isSystemUser = true;
      group = "backup";
      description = "user to run the backup script as";
    };

    users.groups."backup" = {};

    age.secrets.aws-access-key = {
      file = ../../secrets/aws-access-key.age;
      mode = "0400";
      owner = "backup";
      group = "backup";
    };

    systemd.services.pgbackup = {
      description = "service to backup postgres databases";
      environment = {
        CONFIG_FILE_PATH = configFile;
        AWS_ACCESS_KEY_ID = "c735b0f700e602cbdb3af8d50977337c";
        AWS_SECRET_ACCESS_KEY_FILE = config.age.secrets.aws-access-key.path;
        AWS_ENDPOINT_URL = "https://37a8e358fee81bf1f20e08b6ffe72c1d.r2.cloudflarestorage.com";
      };
      path = with pkgs; [postgresql_17 curl gnutar gzip awscli2 jq];
      serviceConfig = {
        Type = "oneshot";
        User = "backup";
        Group = "backup";
        ExecStart = "${backupScript}";
      };
    };
    systemd.timers.pgbackup = {
      description = "Run backup script daily";
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      wantedBy = [ "timers.target" ];
    };
  };
}

