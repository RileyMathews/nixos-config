{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.pgBackup;
  backupScriptPath = pkgs.writeShellScript "pg-backup.sh" cfg.backupScript;
in
  {
    options.pgBackup = {

      backupScript = mkOption {
        type = types.lines;
        default = builtins.readFile(./pg-backup.sh);
        description = "The backup script content.";
      };

      jobs = mkOption {
        type = with lib.types; attrsOf (submodule ({jobName, ...}: {
          options = {
            bucket = mkOption {
              type = str;
            };
            
            database = mkOption {
              type = str;
            };
          };
        }));
      };
    };

    config = {
      systemd.services = lib.mapAttrs (jobName: cfg: {
        path = with pkgs; [postgresql_16 curl gnutar gzip awscli2];
        environment = {
          S3_BUCKET_NAME = cfg.bucket;
          DATABASE_NAME = cfg.database;
        };
        serviceConfig = {
          ExecStart = "${backupScriptPath}";
          EnvironmentFile = "/var/lib/db-backup/env";
        }; 
      }) cfg.jobs;

      systemd.timers = lib.mapAttrs (jobName: cfg: {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      }) cfg.jobs;
    };
  }
