#!/usr/bin/env bash
# Backup script for path-list pattern
# Backs up an explicit list of paths

set -euo pipefail

# Source shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./shared.sh
source "${SCRIPT_DIR}/shared.sh"

# ==============================================================================
# Environment Variables (set by wrapper script):
#   BACKUP_PATHS          - Colon-separated list of paths to backup
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
  if [[ -z "${BACKUP_PATHS:-}" ]]; then
    echo "ERROR: BACKUP_PATHS environment variable is not set" >&2
    exit 1
  fi

  # Initialize repository
  init_repo

  # Run backup
  if ! backup_path_list "$BACKUP_PATHS" "$exclude_args"; then
    on_error "One or more paths failed to backup" "$LINENO" "backup_path_list"
  fi

  # Maintenance
  forget_and_prune

  # Notifications
  gatus_heartbeat "true"
}

main "$@"
