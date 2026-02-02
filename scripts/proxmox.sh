#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but was not found in PATH" >&2
  exit 1
fi

PROXMOX_BASE_URL="https://shipyard:8006"
PROXMOX_NODE="shipyard"
PROXMOX_STORAGE="local"
PROXMOX_DISK_STORAGE="nvme"
PROXMOX_DEBUG="${PROXMOX_DEBUG:-1}"

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

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <vm-name>" >&2
  exit 1
fi

vm_name="$1"

just build-iso

result_path="$(readlink -f result)"
iso_dir="${result_path}/iso"

shopt -s nullglob
iso_candidates=("${iso_dir}"/*.iso)
shopt -u nullglob

if [[ ${#iso_candidates[@]} -eq 0 ]]; then
  echo "ISO not found under ${iso_dir}" >&2
  exit 1
fi

iso_path="${iso_candidates[0]}"
upload_name="${vm_name}.iso"

upload_response="$(_proxmox_api_upload_iso "/api2/json/nodes/${PROXMOX_NODE}/storage/${PROXMOX_STORAGE}/upload" "$iso_path" "$upload_name")"

nextid_json="$(proxmox_get "/api2/json/cluster/nextid")"
nextid="${nextid_json#*\"data\":}"
nextid="${nextid#\"}"
nextid="${nextid# }"
nextid="${nextid%%[^0-9]*}"

if [[ -z "$nextid" ]]; then
  echo "Failed to parse next VMID" >&2
  exit 1
fi

create_response="$(proxmox_post_form "/api2/json/nodes/${PROXMOX_NODE}/qemu" \
  "vmid=${nextid}" \
  "name=${vm_name}" \
  "memory=2048" \
  "sockets=1" \
  "cores=1" \
  "agent=1" \
  "scsihw=virtio-scsi-pci" \
  "scsi0=${PROXMOX_DISK_STORAGE}:32,discard=on" \
  "ide2=${PROXMOX_STORAGE}:iso/${upload_name},media=cdrom" \
  "boot=order=scsi0;ide2;net0" \
  "net0=virtio,bridge=vmbr0")"

start_response="$(proxmox_post_empty "/api2/json/nodes/${PROXMOX_NODE}/qemu/${nextid}/status/start")"

deadline_seconds=300
poll_interval_seconds=5
start_time="$(date +%s)"
last_wait_log=0

while true; do
  now="$(date +%s)"
  if (( now - start_time > deadline_seconds )); then
    echo "Timed out waiting for guest agent IP" >&2
    exit 1
  fi

  if (( now - last_wait_log >= 15 )); then
    echo "Waiting for guest agent IP..." >&2
    last_wait_log="$now"
  fi

  mapfile -t agent_response < <(_proxmox_api_get_raw "/api2/json/nodes/${PROXMOX_NODE}/qemu/${nextid}/agent/network-get-interfaces")
  agent_status="${agent_response[0]}"
  interfaces_json="${agent_response[1]-}"

  if [[ "$agent_status" != "200" ]]; then
    sleep "$poll_interval_seconds"
    continue
  fi

  ip_address="$(jq -r '[.data.result[]?."ip-addresses"[]? | select(."ip-address-type" == "ipv4") | ."ip-address" | select(. != "127.0.0.1") | select((startswith("169.254.")) | not)] | .[0] // empty' <<<"$interfaces_json")"

  if [[ -n "$ip_address" ]]; then
    host_key="$(ssh-keyscan -t ed25519 "$ip_address" 2>/dev/null)"
    host_key_type="$(awk '{print $2}' <<<"$host_key")"
    host_key_value="$(awk '{print $3}' <<<"$host_key")"
    jq -cn --arg ip "$ip_address" --arg key_type "$host_key_type" --arg key "$host_key_value" \
      '{ip: $ip, host_key: {type: $key_type, value: $key}}'
    break
  fi

  sleep "$poll_interval_seconds"
done

