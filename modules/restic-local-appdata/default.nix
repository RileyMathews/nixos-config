{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.resticLocalAppdata;
  pathArgs = concatStringsSep " " (map escapeShellArg cfg.paths);
  excludeArgs = concatStringsSep " " (map (p: "--exclude=" + escapeShellArg p) cfg.excludePatterns);
  backupScriptTemplate = builtins.readFile ./backup.sh;
  backupScriptContent = replaceStrings
    [ "@EXCLUDE_ARGS@" "@PATH_ARGS@" "@AWS_SECRET_ACCESS_KEY_FILE@" "@RESTIC_PASSWORD_FILE@" ]
    [ excludeArgs pathArgs config.age.secrets.aws-access-key.path config.age.secrets.restic-password.path ]
    backupScriptTemplate;

  backupScript = pkgs.writeShellScript "restic-local-appdata-backup.sh" backupScriptContent;
in
{
  options.services.resticLocalAppdata = {
    enable = mkEnableOption "restic backup for local app data";

    paths = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [
        "/var/lib/appdata/homeassistant/config"
        "/var/lib/appdata/homeassistant/media"
        "/var/lib/appdata/homebridge"
      ];
      description = "Absolute directories to back up with restic.";
    };

    excludePatterns = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [
        "/var/lib/appdata/homeassistant/media/doorbell_captures"
      ];
      description = "Paths or globs to exclude from backup.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.paths != [];
        message = "services.resticLocalAppdata.paths must include at least one path.";
      }
      {
        assertion = all (p: hasPrefix "/" p) cfg.paths;
        message = "services.resticLocalAppdata.paths entries must be absolute paths.";
      }
    ];

    age.secrets.aws-access-key = {
      file = ../../secrets/aws-access-key.age;
      mode = "0400";
      owner = "root";
      group = "root";
    };

    age.secrets.restic-password = {
      file = ../../secrets/restic-password.age;
      mode = "0400";
      owner = "root";
      group = "root";
    };

    systemd.services.restic-local-appdata-backup = {
      description = "Backup local app data to restic";
      path = with pkgs; [ restic curl ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = backupScript;
      };
    };

    systemd.timers.restic-local-appdata-backup = {
      description = "Run local app data restic backup daily";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
      unitConfig.Unit = "restic-local-appdata-backup.service";
    };
  };
}
