#!/usr/bin/env bash
# Backup script for sqlite-live-copy pattern
# Backs up SQLite databases using live-copy technique

set -euo pipefail

# Source shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./shared.sh
source "${SCRIPT_DIR}/shared.sh"

# ==============================================================================
# Environment Variables (set by wrapper script):
#   SQLITE_DATABASES      - Colon-separated list of database paths
#   SQLITE_TEMP_DIR       - Temporary directory for live copies
# ==============================================================================

# Validate required variables
die() {
  echo "ERROR: $*" >&2
  exit 1
}

# Main execution
main() {
  # Validate required variables
  if [[ -z "${SQLITE_DATABASES:-}" ]]; then
    die "SQLITE_DATABASES environment variable is not set"
  fi

  if [[ -z "${SQLITE_TEMP_DIR:-}" ]]; then
    die "SQLITE_TEMP_DIR environment variable is not set"
  fi

  # Initialize repository
  init_repo

  # Parse databases
  local IFS=':'
  read -ra databases <<< "$SQLITE_DATABASES"

  if [[ ${#databases[@]} -eq 0 ]]; then
    die "No databases specified"
  fi

  # Create temp directory
  mkdir -p "$SQLITE_TEMP_DIR"
  local temp_dir
  temp_dir=$(mktemp -d -p "$SQLITE_TEMP_DIR" -t restic-sqlite-backup.XXXXXX)
  TEMP_DIRS="${TEMP_DIRS:-} $temp_dir"

  local failed=0
  local copied_dbs=""

  for db_path in "${databases[@]}"; do
    [[ -z "$db_path" ]] && continue

    if [[ ! -f "$db_path" ]]; then
      echo "WARNING: Database not found: $db_path" >&2
      failed=1
      continue
    fi

    local db_name
    db_name=$(basename "$db_path")

    # Use mktemp for unique temp file name
    local temp_copy
    temp_copy=$(mktemp -p "$temp_dir" -t "db-copy.XXXXXX.db")
    TEMP_FILES="${TEMP_FILES:-} $temp_copy"

    echo "Creating live copy of $db_name..."
    # Use sqlite3 .backup command for safe live copying
    if sqlite3 "$db_path" ".backup ${temp_copy}"; then
      copied_dbs="${copied_dbs}:${temp_copy}"
    else
      echo "ERROR: Failed to create live copy of $db_path" >&2
      failed=1
    fi
  done

  # Backup the copied databases
  if [[ -n "$copied_dbs" ]]; then
    # Remove leading colon
    copied_dbs="${copied_dbs#:}"
    local exclude_args=""  # No exclude patterns for SQLite backups
    if ! backup_path_list "$copied_dbs" "$exclude_args"; then
      failed=1
    fi
  fi

  if [[ $failed -ne 0 ]]; then
    on_error "One or more SQLite databases failed to backup" "$LINENO" "sqlite backup"
  fi

  # Maintenance
  forget_and_prune

  # Notifications
  gatus_heartbeat "true"
  notify "${HOSTNAME} backup completed (${BACKUP_TAG})"
}

main "$@"
