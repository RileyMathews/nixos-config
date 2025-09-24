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

    systemd.services.pgbackup = {
      description = "service to backup postgres databases";
      environment = {
        CONFIG_FILE_PATH = configFile;
      };
      serviceConfig = {
        Type = "oneshot";
        User = "backup";
        Group = "backup";
        ExecStart = "${backupScript}";
      };
    };
  };
}

