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
  curl -d "$DATABASE_NAME db backup failed" https://ntfy.rileymathews.com/home-server-alerts
}

set -e
trap 'on_error' ERR
set -uxo pipefail

check_env_var "S3_BUCKET_NAME"
check_env_var "DATABASE_NAME"

current_date=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
backup_dir=/tmp/db_backups/$DATABASE_NAME
backup_output_name=$current_date
backup_full_output_dir=$backup_dir/$backup_output_name

mkdir -p $backup_dir
cd $backup_dir

echo "backing up database $DATABASE_NAME to directory $backup_dir outputing to $backup_output_name"
pg_dump --format=directory --create --clean --if-exists --file=$backup_output_name $DATABASE_NAME

tar -czvf "$backup_output_name.tar.gz" $backup_output_name
