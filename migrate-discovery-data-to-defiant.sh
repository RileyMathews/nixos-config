#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./migrate-discovery-data-to-defiant.sh [--dry-run] [--delete]

Copies local discovery app data directories to defiant.

Run this after stopping the affected apps on discovery and before starting them
on defiant. The script opens SSH connections from this machine to both hosts and
streams each directory from discovery to defiant while preserving ownership and
permissions.

Environment overrides:
  SOURCE_HOST=discovery
  TARGET_HOST=defiant
  SSH_USER=root
  CONFIRM=1        Skip the interactive confirmation prompt.

Options:
  --dry-run        Show what would be copied without changing defiant.
  --delete         Remove each existing target directory before copying it.
USAGE
}

SOURCE_HOST="${SOURCE_HOST:-discovery}"
TARGET_HOST="${TARGET_HOST:-defiant}"
SSH_USER="${SSH_USER:-root}"
DRY_RUN=0
DELETE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --delete)
      DELETE=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [[ "${CONFIRM:-0}" != "1" && "$DRY_RUN" != "1" ]]; then
  cat <<EOF
This will copy these discovery data directories to defiant:
  docker-registry  /var/lib/appdata/docker-registry
  freshrss         /var/www/FreshRSS/data
  karakeep         /var/lib/appdata/karakeep/data
  meilisearch      /var/lib/appdata/meilisearch/data
  bookshelf        /var/lib/bookshelf/data

Stop the corresponding containers on ${SOURCE_HOST} before continuing.
EOF
  read -r -p "Continue? [y/N] " answer
  case "$answer" in
    y|Y|yes|YES)
      ;;
    *)
      echo "Aborted."
      exit 1
      ;;
  esac
fi

quote() {
  printf '%q' "$1"
}

entries=(
  "docker-registry|/var/lib/appdata/docker-registry"
  "freshrss|/var/www/FreshRSS/data"
  "karakeep|/var/lib/appdata/karakeep/data"
  "meilisearch|/var/lib/appdata/meilisearch/data"
  "bookshelf|/var/lib/bookshelf/data"
)

source_target="${SSH_USER}@${SOURCE_HOST}"
target_target="${SSH_USER}@${TARGET_HOST}"
ssh_opts=(-o BatchMode=yes -o StrictHostKeyChecking=accept-new)

if ! ssh "${ssh_opts[@]}" "$source_target" true; then
  cat >&2 <<EOF
Unable to SSH to ${source_target} from this machine.
EOF
  exit 1
fi

if ! ssh "${ssh_opts[@]}" "$target_target" true; then
  cat >&2 <<EOF
Unable to SSH to ${target_target} from this machine.
EOF
  exit 1
fi

for entry in "${entries[@]}"; do
  app="${entry%%|*}"
  path="${entry#*|}"
  parent="${path%/*}"
  base="${path##*/}"
  quoted_path="$(quote "$path")"
  quoted_parent="$(quote "$parent")"
  quoted_base="$(quote "$base")"

  if ! ssh "${ssh_opts[@]}" "$source_target" "test -d $quoted_path"; then
    echo "Skipping ${app}: source directory ${path} does not exist on ${SOURCE_HOST}."
    continue
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    echo "Would copy ${app}: ${SOURCE_HOST}:${path}/ -> ${TARGET_HOST}:${path}/"
    continue
  fi

  echo "Creating ${path} on ${TARGET_HOST}."
  ssh "${ssh_opts[@]}" "$target_target" "mkdir -p $quoted_parent"

  if [[ "$DELETE" == "1" ]]; then
    echo "Removing existing ${path} on ${TARGET_HOST}."
    ssh "${ssh_opts[@]}" "$target_target" "rm -rf --one-file-system $quoted_path && mkdir -p $quoted_parent"
  fi

  echo "Copying ${app}: ${SOURCE_HOST}:${path}/ -> ${TARGET_HOST}:${path}/"
  ssh "${ssh_opts[@]}" "$source_target" \
    "tar --acls --xattrs --xattrs-include='*' --numeric-owner -C $quoted_parent -cpf - $quoted_base" \
    | ssh "${ssh_opts[@]}" "$target_target" \
      "tar --acls --xattrs --xattrs-include='*' --numeric-owner -C $quoted_parent -xpf -"
done
