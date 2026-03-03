{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.resticBackup;

  # Import the library functions for script and service generation
  backupLib = import ./lib.nix { inherit config lib pkgs; };

  # Backup submodule definition
  backupSubmodule = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [ "path-list" "directory-children" "sqlite-live-copy" ];
        description = ''
          The backup pattern to use:
          - path-list: Backup explicit list of paths
          - directory-children: Backup all subdirectories of a parent directory
          - sqlite-live-copy: Safely backup SQLite databases using live-copy
        '';
      };

      gatusHealthcheckId = mkOption {
        type = types.str;
        description = "Gatus external endpoint ID for heartbeat monitoring (required).";
      };

      # path-list options
      paths = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of absolute paths to backup (required for path-list type).";
      };

      # directory-children options
      rootPath = mkOption {
        type = types.str;
        default = "";
        description = "Parent directory whose subdirectories will be backed up (required for directory-children type).";
      };

      # sqlite-live-copy options
      databases = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of SQLite database file paths to backup (required for sqlite-live-copy type).";
      };

      tempDir = mkOption {
        type = types.str;
        default = "/tmp/restic-sqlite-backup";
        description = "Temporary directory for SQLite live copies.";
      };

      # Common options
      excludePatterns = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [
          "*.log"
          "/var/lib/appdata/*/cache/*"
        ];
        description = "Paths or globs to exclude from backup.";
      };
    };
  };

  # Validate a single backup configuration
  validateBackup = name: backup:
    let
      typeValid = true;  # Type is already validated by enum

      pathListValid = backup.type != "path-list" || (backup.paths != [] && all (p: hasPrefix "/" p) backup.paths);
      pathListMsg = ''
        Backup "${name}" has type "path-list" but invalid paths configuration.
        - paths must not be empty
        - paths must be absolute (start with /)
      '';

      dirChildrenValid = backup.type != "directory-children" || (backup.rootPath != "" && hasPrefix "/" backup.rootPath);
      dirChildrenMsg = ''
        Backup "${name}" has type "directory-children" but invalid rootPath.
        - rootPath must be set and be absolute (start with /)
      '';

      sqliteValid = backup.type != "sqlite-live-copy" || (backup.databases != [] && all (p: hasPrefix "/" p) backup.databases);
      sqliteMsg = ''
        Backup "${name}" has type "sqlite-live-copy" but invalid databases configuration.
        - databases must not be empty
        - database paths must be absolute (start with /)
      '';
    in
    [
      {
        assertion = pathListValid;
        message = pathListMsg;
      }
      {
        assertion = dirChildrenValid;
        message = dirChildrenMsg;
      }
      {
        assertion = sqliteValid;
        message = sqliteMsg;
      }
    ];

  # Generate all assertions for all backups
  allAssertions = flatten (mapAttrsToList validateBackup cfg.backups);

in
{
  options.services.resticBackup = {
    enable = mkEnableOption "unified restic backup service";

    cacheDir = mkOption {
      type = types.str;
      default = "/var/cache/restic-backup";
      description = "Base directory for restic cache (per-backup subdirs will be created).";
    };

    backups = mkOption {
      type = types.attrsOf backupSubmodule;
      default = {};
      example = literalExpression ''
        {
          # Path-list backup
          appdata = {
            type = "path-list";
            gatusHealthcheckId = "appdata-backup";
            paths = [
              "/var/lib/appdata/homeassistant/config"
              "/var/lib/appdata/homeassistant/media"
            ];
            excludePatterns = [ "*.log" "cache/*" ];
          };

          # Directory-children backup
          nas-main = {
            type = "directory-children";
            gatusHealthcheckId = "nas-main-backup";
            rootPath = "/mnt/nas-main";
            excludePatterns = [ "*/.aspnet/DataProtection-Keys/*" ];
          };

          # SQLite backup
          databases = {
            type = "sqlite-live-copy";
            gatusHealthcheckId = "sqlite-backup";
            databases = [
              "/var/lib/db/app1.db"
              "/var/lib/db/app2.sqlite"
            ];
            tempDir = "/tmp/restic-sqlite-databases";
          };
        }
      '';
      description = ''
        Set of backup configurations, keyed by backup name.
        Each backup gets its own systemd service and timer pair.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Assertions to validate backup configurations
    assertions = allAssertions ++ [
      {
        assertion = cfg.backups != {};
        message = "services.resticBackup.backups must contain at least one backup configuration.";
      }
    ];

    # =============================================================================
    # Agenix secrets - declared unconditionally as internal implementation detail
    # =============================================================================

    age.secrets.aws-access-key = {
      file = ../../secrets/aws-access-key.age;
      mode = "0400";
      owner = "backup";
      group = "backup";
    };

    age.secrets.restic-password = {
      file = ../../secrets/restic-password.age;
      mode = "0400";
      owner = "backup";
      group = "backup";
    };

    age.secrets.gatus-push-token = {
      file = ../../secrets/gatus-push-token.age;
      mode = "0400";
      owner = "backup";
      group = "backup";
    };

    # Create backup user for running backups
    users.users.backup = {
      isSystemUser = true;
      group = "backup";
      description = "Restic backup service user";
    };

    users.groups.backup = {};

    # =============================================================================
    # Systemd services and timers for each backup
    # =============================================================================

    systemd.services = mapAttrs' (name: backup:
      let
        envContent = backupLib.buildEnvironmentFileContent name backup;
        envFile = pkgs.writeText "restic-backup-${name}.env" envContent;
      in
      nameValuePair "restic-backup-${name}" {
        description = "Restic backup: ${name}";
        path = with pkgs; [ restic curl jq sqlite ];
        environment = {
          # These are consumed by setup.sh
          BACKUP_NAME = name;
          CACHE_DIR = cfg.cacheDir;
          AWS_ACCESS_KEY_ID = "c735b0f700e602cbdb3af8d50977337c";
          AWS_SECRET_ACCESS_KEY_FILE = config.age.secrets.aws-access-key.path;
          RESTIC_PASSWORD_FILE_SOURCE = config.age.secrets.restic-password.path;
          GATUS_PUSH_TOKEN_FILE = config.age.secrets.gatus-push-token.path;
        };
        serviceConfig = {
          Type = "oneshot";
          # Setup credentials in ExecStartPre
          ExecStartPre = "${backupLib.backupScripts}/bin/setup.sh";
          ExecStart = "${backupLib.backupScripts}/bin/wrapper.sh";
          EnvironmentFile = "${envFile}";
          User = "backup";
          Group = "backup";
          CacheDirectory = "restic-backup-${name}";
        };
      }
    ) cfg.backups;

    systemd.timers = mapAttrs' (name: backup:
      nameValuePair "restic-backup-${name}" {
        description = "Timer for restic backup: ${name}";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "2h";
          Unit = "restic-backup-${name}.service";
        };
      }
    ) cfg.backups;
  };
}
