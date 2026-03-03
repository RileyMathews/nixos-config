#!/usr/bin/env bash
# Unified wrapper script for restic backups
# Sources shared.sh, sets up credentials, and executes the appropriate pattern-specific script
#
# Environment variables required:
#   BACKUP_TYPE - one of: path-list, directory-children, sqlite-live-copy
#   AWS_ACCESS_KEY_ID - AWS access key ID
#   AWS_SECRET_ACCESS_KEY_FILE - Path to file containing AWS secret key
#   RESTIC_PASSWORD_FILE_SOURCE - Path to source file containing restic password
#   GATUS_PUSH_TOKEN_FILE - Path to gatus push token file

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# Validate required environment and files
# ==============================================================================

if [[ -z "${BACKUP_TYPE:-}" ]]; then
  echo "ERROR: BACKUP_TYPE environment variable is not set" >&2
  echo "Expected one of: path-list, directory-children, sqlite-live-copy" >&2
  exit 1
fi

if [[ -z "${AWS_SECRET_ACCESS_KEY_FILE:-}" || ! -f "$AWS_SECRET_ACCESS_KEY_FILE" ]]; then
  echo "ERROR: AWS_SECRET_ACCESS_KEY_FILE is not set or does not exist" >&2
  exit 1
fi

if [[ -z "${RESTIC_PASSWORD_FILE_SOURCE:-}" || ! -f "$RESTIC_PASSWORD_FILE_SOURCE" ]]; then
  echo "ERROR: RESTIC_PASSWORD_FILE_SOURCE is not set or does not exist" >&2
  exit 1
fi

# ==============================================================================
# Set up credentials in temporary directory
# ==============================================================================

export CREDENTIALS_DIR
CREDENTIALS_DIR=$(mktemp -d)

# Cleanup on exit
cleanup_credentials() {
  rm -rf "$CREDENTIALS_DIR" 2>/dev/null || true
}
trap cleanup_credentials EXIT

# Create AWS credentials file
AWS_SECRET_ACCESS_KEY=$(cat "$AWS_SECRET_ACCESS_KEY_FILE")
cat > "${CREDENTIALS_DIR}/aws-credentials" << EOF
[default]
aws_access_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
EOF
chmod 600 "${CREDENTIALS_DIR}/aws-credentials"

# Copy restic password file
cp "$RESTIC_PASSWORD_FILE_SOURCE" "${CREDENTIALS_DIR}/restic-password"
chmod 600 "${CREDENTIALS_DIR}/restic-password"

# Export credential file paths for shared.sh and pattern scripts
export AWS_SHARED_CREDENTIALS_FILE="${CREDENTIALS_DIR}/aws-credentials"
export RESTIC_PASSWORD_FILE="${CREDENTIALS_DIR}/restic-password"

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
    echo "Expected one of: path-list, directory-children, sqlite-live-copy" >&2
    exit 1
    ;;
esac
