#!/usr/bin/env bash
# Unified wrapper script for restic backups
# Sources shared.sh and executes the appropriate pattern-specific script
#
# Environment variables required:
#   BACKUP_TYPE - one of: path-list, directory-children, sqlite-live-copy
#   AWS_ACCESS_KEY_ID - AWS access key ID
#   AWS_SECRET_ACCESS_KEY_FILE - Path to file containing AWS secret key
#   RESTIC_PASSWORD_FILE_SOURCE - Path to source file containing restic password

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# Validate required files
# ==============================================================================

if [[ -z "${BACKUP_TYPE:-}" ]]; then
  echo "ERROR: BACKUP_TYPE environment variable is not set" >&2
  exit 1
fi

if [[ ! -f "${AWS_SECRET_ACCESS_KEY_FILE:-}" ]]; then
  echo "ERROR: AWS_SECRET_ACCESS_KEY_FILE does not exist" >&2
  exit 1
fi

if [[ ! -f "${RESTIC_PASSWORD_FILE_SOURCE:-}" ]]; then
  echo "ERROR: RESTIC_PASSWORD_FILE_SOURCE does not exist" >&2
  exit 1
fi

# ==============================================================================
# Set up environment with credential file paths
# ==============================================================================

export AWS_SHARED_CREDENTIALS_FILE="${AWS_SECRET_ACCESS_KEY_FILE}"
export RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE_SOURCE}"

# ==============================================================================
# Source shared functions and hardcoded configuration
# ==============================================================================

# shellcheck source=./shared.sh
source "${SCRIPT_DIR}/shared.sh"

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
    exit 1
    ;;
esac
