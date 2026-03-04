#!/usr/bin/env bash
# Backup script for directory-children pattern
# Backs up all subdirectories of a parent directory

set -euo pipefail

# Source shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./shared.sh
source "${SCRIPT_DIR}/shared.sh"

# ==============================================================================
# Environment Variables (set by wrapper script):
#   BACKUP_ROOT_PATH      - Parent directory whose children will be backed up
#   EXCLUDE_PATTERNS      - Colon-separated list of exclude patterns
# ==============================================================================

# Parse exclude patterns into restic arguments
build_exclude_args() {
  local exclude_args=""
  if [[ -n "${EXCLUDE_PATTERNS:-}" ]]; then
    local IFS=':'
    read -ra patterns <<< "$EXCLUDE_PATTERNS"
    for pattern in "${patterns[@]}"; do
      if [[ -n "$pattern" ]]; then
        exclude_args="${exclude_args} --exclude '${pattern}'"
      fi
    done
  fi
  echo "$exclude_args"
}

# Main execution
main() {
  local exclude_args
  exclude_args=$(build_exclude_args)

  # Validate required variables
  if [[ -z "${BACKUP_ROOT_PATH:-}" ]]; then
    echo "ERROR: BACKUP_ROOT_PATH environment variable is not set" >&2
    exit 1
  fi

  # Initialize repository
  init_repo

  # Run backup
  if ! backup_directory_children "$BACKUP_ROOT_PATH" "$exclude_args"; then
    on_error "One or more directories failed to backup" "$LINENO" "backup_directory_children"
  fi

  # Maintenance
  forget_and_prune

  # Notifications
  gatus_heartbeat "true"
}

main "$@"
