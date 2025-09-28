#! bash

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
  curl -d "remote db backup failed" https://ntfy.rileymathews.com/home-server-alerts
}

backup_database() {
    local host=$1
    local database_name=$2
    local username=$3
    local passwordFile=$4

    current_date=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
    backup_dir=/tmp/db_backups/$database_name
    backup_output_name=$current_date
    backup_full_output_dir=$backup_dir/$backup_output_name
    tar_file_name=$backup_output_name.tar.gz

    mkdir -p $backup_dir
    cd $backup_dir

    echo "backing up database $database_name from $host:$port to directory $backup_dir outputing to $backup_output_name. Using password file $passwordFile and user $username"

    # Set password for pg_dump
    export PGPASSWORD="$(cat $passwordFile)"
    echo $username

    pg_dump \
        --host="$host" \
        --port="5432" \
        --username="$username" \
        --format=directory \
        --create \
        --clean \
        --if-exists \
        --file="$backup_output_name" \
        "$database_name"

    # Clear password from environment
    unset PGPASSWORD

    echo "ran pg_dump on $database_name"

    tar -czvf $tar_file_name $backup_output_name

    echo "uploading $database_name files to s3"

    aws s3 cp $tar_file_name "s3://postgres-backups/$database_name/$tar_file_name"

    echo "Successfully backed up $database_name from $host:$port"
}

echo "starting remote database backup"

set -e
trap 'on_error' ERR

check_env_var "AWS_ACCESS_KEY_ID"
check_env_var "AWS_SECRET_ACCESS_KEY_FILE"
check_env_var "AWS_ENDPOINT_URL"
check_env_var "CONFIG_FILE_PATH"

export AWS_SECRET_ACCESS_KEY=$(cat $AWS_SECRET_ACCESS_KEY_FILE)

# Assuming your JSON file is called data.json
json_file=$CONFIG_FILE_PATH

echo "about to start loop"
# Loop through each object in the array
jq -r '.[] | "\(.name)|\(.host)|\(.user)|\(.passwordFile)"' $json_file | \
while IFS='|' read -r name host user passwordFile; do
    echo "inside loop"
    echo $name
    echo $host
    echo $user
    echo $passwordFile
    backup_database "$host" "$name" "$user" "$passwordFile"
done

# to restore a database. Download the file, unzip it, and run
# pg_restore --dbname=<database> --clean --if-exists --format=directory --jobs=4 backup_dir

