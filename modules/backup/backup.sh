hostname=`cat /etc/hostname`

check_env_var() {
  local var_name="$1"
  
  if [[ -z "${!var_name}" ]]; then
    echo "Error: Environment variable '$var_name' is not set or is empty."
    return 1
  else
    return 0
  fi
}

on_error() {
  echo $1
  curl -d "$hostname backup failed" https://ntfy.rileymathews.com/home-server-alerts
}

set -e
trap 'on_error' ERR


check_env_var "BACKUP_DIR"
check_env_var "RESTIC_REPOSITORY"
check_env_var "RESTIC_PASSWORD"
check_env_var "AWS_ACCESS_KEY_ID"
check_env_var "AWS_SECRET_ACCESS_KEY"


# Initialize the repository if it doesn't exist
if ! restic snapshots >/dev/null 2>&1; then
  echo "Initializing Restic repository..."
  restic init
fi

# Run the backup
restic backup $BACKUP_DIR

curl https://ntfy.rileymathews.com/home-server-alerts -d "$hostname backup ran"
