#!/usr/bin/env bash
# Shared restic backup functions
# This library provides core backup functionality with error handling and monitoring
# Source this file from pattern-specific backup scripts

set -euo pipefail

# ==============================================================================
# Hardcoded Infrastructure Configuration
# These values are internal implementation details, not configurable
# ==============================================================================

RESTIC_REPOSITORY="s3:https://37a8e358fee81bf1f20e08b6ffe72c1d.r2.cloudflarestorage.com/restic-backups"
AWS_ENDPOINT_URL="https://37a8e358fee81bf1f20e08b6ffe72c1d.r2.cloudflarestorage.com"
AWS_ACCESS_KEY_ID="c735b0f700e602cbdb3af8d50977337c"
GATUS_URL="https://gatus.rileymathews.com"
NTFY_URL="https://ntfy.rileymathews.com"
NTFY_TOPIC="home-server-alerts"

# ==============================================================================
# Runtime Configuration (set by environment from systemd service)
# ==============================================================================
: "${AWS_SHARED_CREDENTIALS_FILE:=}"
: "${RESTIC_PASSWORD_FILE:=}"
: "${RESTIC_CACHE_DIR:=/var/cache/restic}"
: "${GATUS_HEALTHCHECK_ID:=}"
: "${GATUS_PUSH_TOKEN_FILE:=}"
: "${BACKUP_TAG:=}"
: "${HOSTNAME:=$(cat /etc/hostname)}"

# ==============================================================================
# Helper Functions
# ==============================================================================

die() {
  echo "ERROR: $*" >&2
  exit 1
}

# Cleanup function - runs on EXIT trap
cleanup() {
  local exit_code=$?

  # Clean up temp files
  if [[ -n "${TEMP_FILES:-}" ]]; then
    for temp_file in $TEMP_FILES; do
      if [[ -f "$temp_file" ]]; then
        rm -f "$temp_file" 2>/dev/null || true
      fi
    done
  fi

  # Clean up temp directories
  if [[ -n "${TEMP_DIRS:-}" ]]; then
    for temp_dir in $TEMP_DIRS; do
      if [[ -d "$temp_dir" ]]; then
        rm -rf "$temp_dir" 2>/dev/null || true
      fi
    done
  fi

  return $exit_code
}

# Set traps early - before any operations that might fail
trap cleanup EXIT

# Send notification to ntfy
notify() {
  local message="$1"
  local priority="${2:-high}"

  if [[ -z "${NTFY_URL:-}" || -z "${NTFY_TOPIC:-}" ]]; then
    return 0
  fi

  curl -fsS -m 15 \
    -H "Priority: $priority" \
    -d "$message" \
    "${NTFY_URL}/${NTFY_TOPIC}" \
    >/dev/null 2>&1 || true
}

# Send heartbeat to gatus
gatus_heartbeat() {
  local success="$1"
  local error="${2:-}"

  # Skip if no healthcheck ID is configured
  if [[ -z "${GATUS_HEALTHCHECK_ID:-}" ]]; then
    return 0
  fi

  if [[ -z "${GATUS_URL:-}" ]]; then
    echo "WARNING: GATUS_URL not set, skipping heartbeat" >&2
    return 0
  fi

  # Read token directly from file - no grep parsing needed
  local token=""
  if [[ -n "${GATUS_PUSH_TOKEN_FILE:-}" && -f "$GATUS_PUSH_TOKEN_FILE" ]]; then
    token=$(cat "$GATUS_PUSH_TOKEN_FILE" 2>/dev/null | tr -d '[:space:]') || true
  fi

  # Build the URL
  local url="${GATUS_URL}/api/v1/endpoints/${GATUS_HEALTHCHECK_ID}/external?success=${success}"

  if [[ -n "$error" ]]; then
    # URL-encode the error message
    local encoded_error
    encoded_error=$(echo "$error" | jq -Rs . 2>/dev/null | tr -d '"' || echo "$error")
    url="${url}&error=${encoded_error}"
  fi

  # Send the heartbeat
  if [[ -n "$token" ]]; then
    curl -fsS -m 15 -X POST \
      -H "Authorization: Bearer ${token}" \
      "$url" \
      >/dev/null 2>&1 || true
  else
    curl -fsS -m 15 -X POST \
      "$url" \
      >/dev/null 2>&1 || true
  fi
}

# Error handler - runs on ERR trap
on_error() {
  local error_msg="${1:-backup failed}"
  local line_no="${2:-unknown}"
  local command="${3:-unknown}"

  echo "ERROR on line $line_no: '$command' - $error_msg" >&2

  # Always attempt to notify, even in degraded states
  notify "${HOSTNAME} backup failed (${BACKUP_TAG}): $error_msg at line $line_no" "urgent"
  gatus_heartbeat "false" "$error_msg"

  exit 1
}

# Set up error trapping
trap 'on_error "$?" "$LINENO" "$BASH_COMMAND"' ERR

# ==============================================================================
# Backup Functions
# ==============================================================================

# Initialize the restic repository if it doesn't exist
init_repo() {
  if ! restic --retry-lock 5h snapshots >/dev/null 2>&1; then
    echo "Initializing restic repository..."
    restic --retry-lock 5h init
  fi
}

# Backup a single path with optional extra tag and exclude args
backup_path() {
  local path="$1"
  local extra_tag="${2:-}"
  local exclude_args="${3:-}"

  local tags=("--host" "$HOSTNAME" "--tag" "$BACKUP_TAG")
  if [[ -n "$extra_tag" ]]; then
    tags+=("--tag" "$extra_tag")
  fi

  if [[ ! -e "$path" ]]; then
    echo "WARNING: Path does not exist: $path" >&2
    return 1
  fi

  echo "Backing up: $path"

  # Use eval carefully to expand exclude_args
  # shellcheck disable=SC2086
  restic --retry-lock 5h backup \
    "${tags[@]}" \
    $exclude_args \
    "$path"
}

# Backup a list of paths
backup_path_list() {
  local paths_str="$1"
  local exclude_args="${2:-}"

  local IFS=':'
  read -ra paths <<< "$paths_str"

  local failed=0
  for path in "${paths[@]}"; do
    if [[ -n "$path" ]]; then
      if ! backup_path "$path" "" "$exclude_args"; then
        failed=1
      fi
    fi
  done

  return $failed
}

# Backup all subdirectories of a parent directory
backup_directory_children() {
  local parent_dir="$1"
  local exclude_args="${2:-}"

  if [[ ! -d "$parent_dir" ]]; then
    echo "ERROR: Parent directory does not exist: $parent_dir" >&2
    return 1
  fi

  local found_dirs=0
  local failed=0

  for child_path in "$parent_dir"/*; do
    [[ -d "$child_path" ]] || continue

    local child_name
    child_name=$(basename "$child_path")
    found_dirs=1

    if ! backup_path "$child_path" "dataset:${child_name}" "$exclude_args"; then
      failed=1
    fi
  done

  if [[ $found_dirs -eq 0 ]]; then
    echo "ERROR: No subdirectories found under $parent_dir" >&2
    return 1
  fi

  return $failed
}

# Run forget and prune with standard retention policy
forget_and_prune() {
  echo "Running forget and prune..."

  restic --retry-lock 5h forget --prune \
    --host "$HOSTNAME" \
    --tag "$BACKUP_TAG" \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6
}
