#!/usr/bin/env bash
# Unified wrapper script for restic backups
# Sources shared.sh and executes the appropriate pattern-specific script
#
# Environment variables required:
#   BACKUP_TYPE - one of: path-list, directory-children, sqlite-live-copy
#
# Additional variables are read from the EnvironmentFile and passed through

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared functions and hardcoded configuration
# shellcheck source=./shared.sh
source "${SCRIPT_DIR}/shared.sh"

# ==============================================================================
# Validate required environment
# ==============================================================================

if [[ -z "${BACKUP_TYPE:-}" ]]; then
  echo "ERROR: BACKUP_TYPE environment variable is not set" >&2
  echo "Expected one of: path-list, directory-children, sqlite-live-copy" >&2
  exit 1
fi

# Validate credential files exist
if [[ -z "${AWS_SHARED_CREDENTIALS_FILE:-}" || ! -f "$AWS_SHARED_CREDENTIALS_FILE" ]]; then
  echo "ERROR: AWS_SHARED_CREDENTIALS_FILE is not set or does not exist" >&2
  exit 1
fi

if [[ -z "${RESTIC_PASSWORD_FILE:-}" || ! -f "$RESTIC_PASSWORD_FILE" ]]; then
  echo "ERROR: RESTIC_PASSWORD_FILE is not set or does not exist" >&2
  exit 1
fi

# ==============================================================================
# Select and execute the pattern-specific script
# ==============================================================================

case "$BACKUP_TYPE" in
  path-list)
    exec "${SCRIPT_DIR}/backup-path-list.sh"
    ;;
  directory-children)
    exec "${SCRIPT_DIR}/backup-directory-children.sh"
    ;;
  sqlite-live-copy)
    exec "${SCRIPT_DIR}/backup-sqlite-live-copy.sh"
    ;;
  *)
    echo "ERROR: Unknown BACKUP_TYPE: $BACKUP_TYPE" >&2
    echo "Expected one of: path-list, directory-children, sqlite-live-copy" >&2
    exit 1
    ;;
esac
