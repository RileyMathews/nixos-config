set -euo pipefail

hostname="$(cat /etc/hostname)"

usage() {
  cat >&2 <<'EOF'
Usage:
  backup.sh backup-path --path <absolute-path> [--exclude <pattern> ...]
  backup.sh prune-all
EOF
  exit 2
}

notify() {
  curl -fsS -m 15 -d "$1" "https://ntfy.rileymathews.com/home-server-alerts" >/dev/null || true
}

on_error() {
  notify "${hostname} local appdata backup failed"
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

if ! restic snapshots >/dev/null 2>&1; then
  restic init
fi

cmd="${1:-}"
if [[ -z "$cmd" ]]; then
  usage
fi
shift

case "$cmd" in
  backup-path)
    backup_path=""
    excludes=()

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --path)
          [[ $# -ge 2 ]] || usage
          backup_path="$2"
          shift 2
          ;;
        --exclude)
          [[ $# -ge 2 ]] || usage
          excludes+=("--exclude" "$2")
          shift 2
          ;;
        *)
          usage
          ;;
      esac
    done

    if [[ -z "$backup_path" || "$backup_path" != /* ]]; then
      usage
    fi

    restic backup --host "$hostname" --tag local-appdata "${excludes[@]}" "$backup_path"
    ;;

  prune-all)
    restic forget --prune \
      --host "$hostname" \
      --tag local-appdata \
      --keep-daily 7 \
      --keep-weekly 4 \
      --keep-monthly 6

    notify "${hostname} local appdata backup ran"
    ;;

  *)
    usage
    ;;
esac
