#!/usr/bin/env bash

require_cmd() {
  local cmd="$1"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "${cmd} is required but was not found in PATH" >&2
    exit 1
  fi
}

replace_hostname_placeholder() {
  local config_path="$1"
  local hostname="$2"

  if [[ ! -f "$config_path" ]]; then
    echo "Missing configuration.nix at ${config_path}" >&2
    return 1
  fi

  if ! grep -q '{{template}}' "$config_path"; then
    echo "Expected hostname placeholder {{template}} not found in ${config_path}" >&2
    return 1
  fi

  local escaped_hostname="$hostname"
  escaped_hostname="${escaped_hostname//&/\\&}"
  escaped_hostname="${escaped_hostname//\//\\/}"
  sed -i "s/{{template}}/${escaped_hostname}/g" "$config_path"
}

_proxmox_api_request() {
  local method="$1"
  local path="$2"
  local data="${3-}"

  if [[ -z "${PROXMOX_API_TOKEN-}" ]]; then
    echo "PROXMOX_API_TOKEN is not set" >&2
    return 1
  fi

  if [[ -z "$path" || "$path" != /* ]]; then
    echo "Endpoint path must start with /" >&2
    return 1
  fi

  local url="${PROXMOX_BASE_URL}${path}"

  local response
  local status

  if [[ "$method" == "POST" ]]; then
    response=$(curl -sS --insecure \
      -X "$method" \
      -H "Authorization: PVEAPIToken=root@pam!ds9-nixos-repo-token=${PROXMOX_API_TOKEN}" \
      -H "Content-Type: application/json" \
      --data "$data" \
      -w "\n%{http_code}" \
      "$url")
  else
    response=$(curl -sS --insecure \
      -X "$method" \
      -H "Authorization: PVEAPIToken=root@pam!ds9-nixos-repo-token=${PROXMOX_API_TOKEN}" \
      -w "\n%{http_code}" \
      "$url")
  fi

  status="${response##*$'\n'}"
  response="${response%$'\n'*}"

  if [[ "$PROXMOX_DEBUG" == "1" ]]; then
    echo "[DEBUG] ${method} ${path} -> HTTP ${status}" >&2
    if [[ -n "$response" ]]; then
      echo "[DEBUG] Response: $response" >&2
    fi
  fi

  if [[ "$status" != "200" ]]; then
    echo "Request failed with HTTP $status" >&2
    if [[ -n "$response" ]]; then
      echo "$response" >&2
    fi
    return 1
  fi

  echo "$response"
}

_proxmox_api_post_empty() {
  local path="$1"

  if [[ -z "${PROXMOX_API_TOKEN-}" ]]; then
    echo "PROXMOX_API_TOKEN is not set" >&2
    return 1
  fi

  if [[ -z "$path" || "$path" != /* ]]; then
    echo "Endpoint path must start with /" >&2
    return 1
  fi

  local url="${PROXMOX_BASE_URL}${path}"
  local response
  local status

  response=$(curl -sS --insecure \
    -X "POST" \
    -H "Authorization: PVEAPIToken=root@pam!ds9-nixos-repo-token=${PROXMOX_API_TOKEN}" \
    -w "\n%{http_code}" \
    "$url")

  status="${response##*$'\n'}"
  response="${response%$'\n'*}"

  if [[ "$PROXMOX_DEBUG" == "1" ]]; then
    echo "[DEBUG] POST ${path} (empty) -> HTTP ${status}" >&2
    if [[ -n "$response" ]]; then
      echo "[DEBUG] Response: $response" >&2
    fi
  fi

  if [[ "$status" != "200" ]]; then
    echo "Request failed with HTTP $status" >&2
    if [[ -n "$response" ]]; then
      echo "$response" >&2
    fi
    return 1
  fi

  echo "$response"
}

_proxmox_api_get_raw() {
  local path="$1"

  if [[ -z "${PROXMOX_API_TOKEN-}" ]]; then
    echo "PROXMOX_API_TOKEN is not set" >&2
    return 1
  fi

  if [[ -z "$path" || "$path" != /* ]]; then
    echo "Endpoint path must start with /" >&2
    return 1
  fi

  local url="${PROXMOX_BASE_URL}${path}"
  local response
  local status

  response=$(curl -sS --insecure \
    -X "GET" \
    -H "Authorization: PVEAPIToken=root@pam!ds9-nixos-repo-token=${PROXMOX_API_TOKEN}" \
    -w "\n%{http_code}" \
    "$url")

  status="${response##*$'\n'}"
  response="${response%$'\n'*}"

  if [[ "$PROXMOX_DEBUG" == "1" ]]; then
    echo "[DEBUG] GET ${path} (raw) -> HTTP ${status}" >&2
    if [[ -n "$response" ]]; then
      echo "[DEBUG] Response: $response" >&2
    fi
  fi

  echo "$status"
  echo "$response"
}

_proxmox_api_post_form() {
  local path="$1"
  shift

  if [[ -z "${PROXMOX_API_TOKEN-}" ]]; then
    echo "PROXMOX_API_TOKEN is not set" >&2
    return 1
  fi

  if [[ -z "$path" || "$path" != /* ]]; then
    echo "Endpoint path must start with /" >&2
    return 1
  fi

  local url="${PROXMOX_BASE_URL}${path}"
  local response
  local status
  local curl_args=()

  for kv in "$@"; do
    curl_args+=("--data-urlencode" "$kv")
  done

  response=$(curl -sS --insecure \
    -H "Authorization: PVEAPIToken=root@pam!ds9-nixos-repo-token=${PROXMOX_API_TOKEN}" \
    "${curl_args[@]}" \
    -w "\n%{http_code}" \
    "$url")

  status="${response##*$'\n'}"
  response="${response%$'\n'*}"

  if [[ "$PROXMOX_DEBUG" == "1" ]]; then
    echo "[DEBUG] POST ${path} -> HTTP ${status}" >&2
    if [[ -n "$response" ]]; then
      echo "[DEBUG] Response: $response" >&2
    fi
  fi

  if [[ "$status" != "200" ]]; then
    echo "Request failed with HTTP $status" >&2
    if [[ -n "$response" ]]; then
      echo "$response" >&2
    fi
    return 1
  fi

  echo "$response"
}

_proxmox_api_upload_iso() {
  local path="$1"
  local file_path="$2"
  local upload_name="$3"

  if [[ -z "${PROXMOX_API_TOKEN-}" ]]; then
    echo "PROXMOX_API_TOKEN is not set" >&2
    return 1
  fi

  if [[ -z "$path" || "$path" != /* ]]; then
    echo "Endpoint path must start with /" >&2
    return 1
  fi

  if [[ ! -f "$file_path" ]]; then
    echo "ISO not found at $file_path" >&2
    return 1
  fi

  local url="${PROXMOX_BASE_URL}${path}"
  local response
  local status

  response=$(curl -sS --insecure \
    -H "Authorization: PVEAPIToken=root@pam!ds9-nixos-repo-token=${PROXMOX_API_TOKEN}" \
    -F "content=iso" \
    -F "filename=@${file_path};filename=${upload_name}" \
    -w "\n%{http_code}" \
    "$url")

  status="${response##*$'\n'}"
  response="${response%$'\n'*}"

  if [[ "$PROXMOX_DEBUG" == "1" ]]; then
    echo "[DEBUG] POST ${path} (upload) -> HTTP ${status}" >&2
    if [[ -n "$response" ]]; then
      echo "[DEBUG] Response: $response" >&2
    fi
  fi

  if [[ "$status" != "200" ]]; then
    echo "Upload failed with HTTP $status" >&2
    if [[ -n "$response" ]]; then
      echo "$response" >&2
    fi
    return 1
  fi

  echo "$response"
}

proxmox_get() {
  local path="$1"
  _proxmox_api_request "GET" "$path"
}

proxmox_post() {
  local path="$1"
  local data="$2"
  _proxmox_api_request "POST" "$path" "$data"
}

proxmox_post_form() {
  local path="$1"
  shift
  _proxmox_api_post_form "$path" "$@"
}

proxmox_post_empty() {
  local path="$1"
  _proxmox_api_post_empty "$path"
}

proxmox_delete() {
  local path="$1"
  _proxmox_api_request "DELETE" "$path"
}
