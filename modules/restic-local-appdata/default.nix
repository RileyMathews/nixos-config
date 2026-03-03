{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.resticLocalAppdata;
  excludeArgs = concatMapStringsSep " " (p: "--exclude " + escapeShellArg p) cfg.excludePatterns;
  backupScript = pkgs.writeShellScript "restic-local-appdata-backup.sh" (builtins.readFile ./backup.sh);
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

    gatusHealthcheckId = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "my-backup";
      description = "Gatus external endpoint ID for heartbeat monitoring.";
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

    age.secrets.gatus-push-token = {
      file = ../../secrets/gatus-push-token.age;
      mode = "0400";
      owner = "root";
      group = "root";
    };

    systemd.services.restic-local-appdata-backup = {
      description = "Backup local app data to restic";
      path = with pkgs; [ restic curl jq ];
      environment = {
        AWS_SECRET_ACCESS_KEY_FILE = config.age.secrets.aws-access-key.path;
        RESTIC_PASSWORD_FILE = config.age.secrets.restic-password.path;
        RESTIC_CACHE_DIR = "/var/cache/restic-local-appdata";
        GATUS_URL = "https://gatus.rileymathews.com";
        BACKUP_PATHS = concatStringsSep ":" cfg.paths;
        EXCLUDE_ARGS = excludeArgs;
      }
      // optionalAttrs (cfg.gatusHealthcheckId != null) {
        GATUS_HEALTHCHECK_ID = cfg.gatusHealthcheckId;
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${backupScript}";
        CacheDirectory = "restic-local-appdata";
        EnvironmentFile = config.age.secrets.gatus-push-token.path;
      };
    };

    systemd.timers.restic-local-appdata-backup = {
      description = "Run local app data restic backup daily";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "2h";
        Unit = "restic-local-appdata-backup.service";
      };
    };
  };
}
