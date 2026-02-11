set -euo pipefail

hostname="$(cat /etc/hostname)"

notify() {
  curl -fsS -m 15 -d "$1" "https://ntfy.rileymathews.com/home-server-alerts" >/dev/null || true
}

on_error() {
  notify "${hostname} local appdata backup failed"
}

trap on_error ERR

export RESTIC_REPOSITORY="s3:https://37a8e358fee81bf1f20e08b6ffe72c1d.r2.cloudflarestorage.com/restic-backups"
export AWS_ENDPOINT_URL="https://37a8e358fee81bf1f20e08b6ffe72c1d.r2.cloudflarestorage.com"
export AWS_ACCESS_KEY_ID="c735b0f700e602cbdb3af8d50977337c"
export AWS_SECRET_ACCESS_KEY="$(cat @AWS_SECRET_ACCESS_KEY_FILE@)"
export RESTIC_PASSWORD="$(cat @RESTIC_PASSWORD_FILE@)"

if ! restic snapshots >/dev/null 2>&1; then
  restic init
fi

restic backup --host "$hostname" --tag local-appdata @EXCLUDE_ARGS@ @PATH_ARGS@

restic forget --prune \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6

notify "${hostname} local appdata backup ran"
