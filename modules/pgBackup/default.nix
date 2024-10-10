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
            command = mkOption {
              type = str;
            };
          };
        }));
      };
    };

    config = {
      systemd.services = lib.mapAttrs (jobName: cfg: {
        serviceConfig = {
          ExecStart = "${backupScriptPath}";
        }; 
      }) cfg.jobs;
    };
  }
