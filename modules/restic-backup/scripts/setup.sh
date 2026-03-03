#!/usr/bin/env bash
# Setup script for restic backup - prepares credentials and cache directory
#
# Environment variables expected:
#   BACKUP_NAME                - Name of the backup (used for cache directory naming)
#   CACHE_DIR                  - Base cache directory path
#   AWS_ACCESS_KEY_ID          - AWS access key ID
#   AWS_SECRET_ACCESS_KEY_FILE - Path to file containing AWS secret key
#   RESTIC_PASSWORD_FILE_SOURCE - Path to source file containing restic password
#
# Note: RESTIC_PASSWORD_FILE is set by the main EnvironmentFile to point to
# the destination where we copy the password.

set -euo pipefail

# Validate required environment
if [[ -z "${BACKUP_NAME:-}" ]]; then
  echo "ERROR: BACKUP_NAME environment variable is not set" >&2
  exit 1
fi

if [[ -z "${CACHE_DIR:-}" ]]; then
  echo "ERROR: CACHE_DIR environment variable is not set" >&2
  exit 1
fi

if [[ -z "${AWS_ACCESS_KEY_ID:-}" ]]; then
  echo "ERROR: AWS_ACCESS_KEY_ID environment variable is not set" >&2
  exit 1
fi

if [[ -z "${AWS_SECRET_ACCESS_KEY_FILE:-}" || ! -f "$AWS_SECRET_ACCESS_KEY_FILE" ]]; then
  echo "ERROR: AWS_SECRET_ACCESS_KEY_FILE is not set or file does not exist" >&2
  exit 1
fi

if [[ -z "${RESTIC_PASSWORD_FILE_SOURCE:-}" || ! -f "$RESTIC_PASSWORD_FILE_SOURCE" ]]; then
  echo "ERROR: RESTIC_PASSWORD_FILE_SOURCE is not set or file does not exist" >&2
  exit 1
fi

# Create cache directory
BACKUP_CACHE_DIR="${CACHE_DIR}/${BACKUP_NAME}"
mkdir -p "$BACKUP_CACHE_DIR"
chmod 750 "$BACKUP_CACHE_DIR"

# Read secret key
AWS_SECRET_ACCESS_KEY=$(cat "$AWS_SECRET_ACCESS_KEY_FILE")

# Create AWS credentials file
cat > "${BACKUP_CACHE_DIR}/aws-credentials" << EOF
[default]
aws_access_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
EOF
chmod 600 "${BACKUP_CACHE_DIR}/aws-credentials"

# Copy restic password file (RESTIC_PASSWORD_FILE points to destination)
cp "$RESTIC_PASSWORD_FILE_SOURCE" "$RESTIC_PASSWORD_FILE"
chmod 600 "$RESTIC_PASSWORD_FILE"

echo "Setup complete for backup: ${BACKUP_NAME}"
