{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.resticBackup;

  # Create a derivation that installs the scripts to the nix store
  backupScripts = pkgs.stdenv.mkDerivation {
    name = "restic-backup-scripts";
    src = ./scripts;
    installPhase = ''
      mkdir -p $out/bin
      cp *.sh $out/bin/
      chmod +x $out/bin/*.sh
    '';
  };

  # Convert a list of strings to a colon-separated string
  listToColonSeparated = list: concatStringsSep ":" list;

  # Build environment file content for a backup configuration
  buildEnvironmentFileContent = backupName: backupConfig:
    let
      # Common environment variables
      commonVars = {
        BACKUP_TYPE = backupConfig.type;
        BACKUP_TAG = backupName;
        GATUS_HEALTHCHECK_ID = backupConfig.gatusHealthcheckId;
        RESTIC_CACHE_DIR = "${cfg.cacheDir}/${backupName}";
        # Credential file paths (created by setup.sh)
        AWS_SHARED_CREDENTIALS_FILE = "${cfg.cacheDir}/${backupName}/aws-credentials";
        RESTIC_PASSWORD_FILE = "${cfg.cacheDir}/${backupName}/restic-password";
      };

      # Pattern-specific variables
      patternVars =
        if backupConfig.type == "path-list" then {
          BACKUP_PATHS = listToColonSeparated backupConfig.paths;
          EXCLUDE_PATTERNS = listToColonSeparated backupConfig.excludePatterns;
        }
        else if backupConfig.type == "directory-children" then {
          BACKUP_ROOT_PATH = backupConfig.rootPath;
          EXCLUDE_PATTERNS = listToColonSeparated backupConfig.excludePatterns;
        }
        else if backupConfig.type == "sqlite-live-copy" then {
          SQLITE_DATABASES = listToColonSeparated backupConfig.databases;
          SQLITE_TEMP_DIR = backupConfig.tempDir;
        }
        else {};

      allVars = commonVars // patternVars;
    in
    concatStringsSep "\n" (mapAttrsToList (name: value: "${name}=${lib.escapeShellArg value}") allVars);

in
{
  inherit backupScripts buildEnvironmentFileContent;
}
