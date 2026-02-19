set -euo pipefail

hostname="$(cat /etc/hostname)"
nas_root="/mnt/nas-main"

notify() {
  curl -fsS -m 15 -H "Priority: high" -d "$1" "https://ntfy.rileymathews.com/home-server-alerts" >/dev/null || true
}

on_error() {
  notify "${hostname} nas main backup failed"
}

trap on_error ERR

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

if ! mountpoint -q "$nas_root"; then
  echo "Expected mountpoint at $nas_root, but it is not mounted" >&2
  exit 1
fi

found_dirs=0
for dataset_path in "$nas_root"/*; do
  [[ -d "$dataset_path" ]] || continue
  dataset_name="$(basename "$dataset_path")"
  found_dirs=1
  restic --retry-lock 5h backup \
    --host "$hostname" \
    --tag nas-main \
    --tag "dataset:${dataset_name}" \
    "$@" \
    "$dataset_path"
done

if [[ $found_dirs -eq 0 ]]; then
  echo "No directories found to back up under $nas_root" >&2
  exit 1
fi

restic --retry-lock 5h forget --prune \
  --host "$hostname" \
  --tag nas-main \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6
