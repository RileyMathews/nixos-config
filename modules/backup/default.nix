# backup.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.backup;
  backupScriptPath = pkgs.writeShellScript "backup-script.sh" cfg.backupScript;
in
{
  #### Define Options ####
  options.services.backup = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the backup service and timer.";
    };

    backupScript = mkOption {
      type = types.lines;
      default = builtins.readFile(./backup.sh);
      description = "The backup script content.";
    };

    resticRepository = mkOption {
      type = types.string;
      default = null;
      description = "The restic repository location";
    };

    backupDir = mkOption {
      type = types.string;
      default = null;
      description = "The directory to backup";
    };
  };

  #### Configure the Service and Timer ####
  config = mkIf cfg.enable ({
    assertions = [
      {
        assertion = cfg.resticRepository != null;
        message = "The option 'resticRepository' must be set";
      }
      {
        assertion = cfg.backupDir != null;
        message = "The option 'backupDir' must be set";
      }
    ];

    # Define the systemd service
    systemd.services.backup = {
      description = "Backup Service";
      path = with pkgs; [curl restic];
      environment = {
        BACKUP_DIR = cfg.backupDir;
        RESTIC_REPOSITORY = cfg.resticRepository;
      };
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = "/var/lib/backup/env";
        ExecStart = "${backupScriptPath}";
      };
    };

    # Define the systemd timer
    systemd.timers.backup = {
      description = "Backup Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      unitConfig.Unit = "backup.service";
    };
  });
}

