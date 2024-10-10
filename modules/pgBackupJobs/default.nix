{ lib, config, ... }:
with lib;
let
  cfg = config.pgBackupJobs;
in
  {
    options.pgBackupJobs = lib.mkOption {
      type = with lib.types; attrsOf (submodule ({jobName, ...}: {
        options = {
          command = mkOption {
            type = str;
          };
        };
      }));
    };

    config = {
      systemd.services = lib.mapAttrs (jobName: cfg: {
        serviceConfig = {
          ExecStart = cfg.command;
        }; 
      }) cfg;
    };
  }
