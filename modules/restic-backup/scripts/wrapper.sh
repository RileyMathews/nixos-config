#!/usr/bin/env bash
# Unified wrapper script for restic backups
# Sources shared.sh and executes the appropriate pattern-specific script

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
  echo "ERROR: AWS_SECRET_ACCESS_KEY_FILE does not exist: ${AWS_SECRET_ACCESS_KEY_FILE:-}" >&2
  exit 1
fi

if [[ ! -f "${RESTIC_PASSWORD_FILE_SOURCE:-}" ]]; then
  echo "ERROR: RESTIC_PASSWORD_FILE_SOURCE does not exist: ${RESTIC_PASSWORD_FILE_SOURCE:-}" >&2
  exit 1
fi

# ==============================================================================
# Set environment variables for restic
# ==============================================================================

# Read AWS secret and export it directly
export AWS_SECRET_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=$(cat "$AWS_SECRET_ACCESS_KEY_FILE")

# Point restic to password file
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
