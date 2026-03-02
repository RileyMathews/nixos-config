set -euo pipefail

hostname="$(cat /etc/hostname)"

notify() {
  curl -fsS -m 15 -H "Priority: high" -d "$1" "https://ntfy.rileymathews.com/home-server-alerts" >/dev/null || true
}

gatus_heartbeat() {
  local status="$1"
  local error="${2:-}"

  if [[ -z "${GATUS_HEALTHCHECK_ID:-}" ]]; then
    return
  fi

  local token=""
  if [[ -n "${GATUS_PUSH_TOKEN:-}" ]]; then
    token="$GATUS_PUSH_TOKEN"
  elif [[ -n "${GATUS_PUSH_TOKEN_FILE:-}" ]]; then
    token="$(grep -v '^export ' "$GATUS_PUSH_TOKEN_FILE" | grep -oP '^GATUS_PUSH_TOKEN=\K.*' || true)"
  fi

  if [[ -z "$token" ]]; then
    return
  fi

  local url="${GATUS_URL:-https://gatus.rileymathews.com}/api/v1/endpoints/${GATUS_HEALTHCHECK_ID}/external?success=${status}"
  if [[ -n "$error" ]]; then
    url+="&error=$(echo "$error" | jq -Rs .)"
  fi

  curl -fsS -m 15 -X POST -H "Authorization: Bearer ${GATUS_PUSH_TOKEN}" "$url" >/dev/null 2>&1 || true
}

on_error() {
  local error="${1:-backup failed}"
  notify "${hostname} local appdata backup failed: $error"
  gatus_heartbeat "false" "$error"
  exit 1
}

trap 'on_error "$BASH_COMMAND"' ERR

if [[ -z "${AWS_SECRET_ACCESS_KEY_FILE:-}" || -z "${RESTIC_PASSWORD_FILE:-}" ]]; then
  echo "AWS_SECRET_ACCESS_KEY_FILE and RESTIC_PASSWORD_FILE must be set" >&2
  exit 2
fi

export RESTIC_REPOSITORY="s3:https://37a8e358fee81bf1f20e08b6ffe72c1d.r2.cloudflarestorage.com/restic-backups"
export AWS_ENDPOINT_URL="https://37a8e358fee81bf1f20e08b6ffe72c1d.r2.cloudflarestorage.com"
export AWS_ACCESS_KEY_ID="c735b0f700e602cbdb3af8d50977337c"
export AWS_SECRET_ACCESS_KEY="$(cat "$AWS_SECRET_ACCESS_KEY_FILE")"
export RESTIC_PASSWORD="$(cat "$RESTIC_PASSWORD_FILE")"

if ! restic --retry-lock 5h snapshots >/dev/null 2>&1; then
  restic --retry-lock 5h init
fi

IFS=':' read -ra PATHS <<< "${BACKUP_PATHS:-}"
for path in "${PATHS[@]}"; do
  restic --retry-lock 5h backup --host "$hostname" --tag local-appdata ${EXCLUDE_ARGS:-} "$path"
done

restic --retry-lock 5h forget --prune \
  --host "$hostname" \
  --tag local-appdata \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6

gatus_heartbeat "true"
