#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/proxmox-lib.sh"

require_cmd jq
require_cmd curl
require_cmd ssh-keyscan
require_cmd just
require_cmd agenix
require_cmd ping

PROXMOX_BASE_URL="https://shipyard:8006"
PROXMOX_NODE="shipyard"
PROXMOX_STORAGE="local"
PROXMOX_DISK_STORAGE="nvme"
PROXMOX_DEBUG="${PROXMOX_DEBUG:-1}"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <vm-name>" >&2
  exit 1
fi

vm_name="$1"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
hosts_dir="${repo_root}/hosts"
host_dir="${hosts_dir}/${vm_name}"
host_template_pre_dir="${hosts_dir}/template-pre"
host_template_post_dir="${hosts_dir}/template-post"
host_keys_dir="${repo_root}/secrets/host-keys"
host_key_path="${host_keys_dir}/${vm_name}.pub"

if [[ -e "$host_dir" ]]; then
  echo "Host directory already exists at ${host_dir}" >&2
  exit 1
fi

if [[ -e "$host_key_path" ]]; then
  echo "Host key already exists at ${host_key_path}" >&2
  exit 1
fi

if [[ ! -d "$host_template_pre_dir" ]]; then
  echo "Host pre-provision template directory not found at ${host_template_pre_dir}" >&2
  exit 1
fi

if [[ ! -d "$host_template_post_dir" ]]; then
  echo "Host post-provision template directory not found at ${host_template_post_dir}" >&2
  exit 1
fi

pushd "$repo_root" >/dev/null
cp -a "$host_template_pre_dir" "$host_dir"
replace_hostname_placeholder "${host_dir}/configuration.nix" "$vm_name"

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
    break
  fi

  sleep "$poll_interval_seconds"
done

if [[ -z "${ip_address-}" ]]; then
  echo "Failed to resolve guest IP" >&2
  exit 1
fi

just provision ".#${vm_name}" "${ip_address}"

post_provision_deadline_seconds=300
post_provision_start_time="$(date +%s)"
post_provision_log_time=0

while true; do
  now="$(date +%s)"
  if (( now - post_provision_start_time > post_provision_deadline_seconds )); then
    echo "Timed out waiting for host to respond to ping after provision" >&2
    exit 1
  fi

  if (( now - post_provision_log_time >= 15 )); then
    echo "Waiting for host to respond to ping after provision..." >&2
    post_provision_log_time="$now"
  fi

  if ping -c 1 -W 2 "$ip_address" >/dev/null 2>&1; then
    break
  fi

  sleep "$poll_interval_seconds"
done

host_key="$(ssh-keyscan -t ed25519 "$ip_address" 2>/dev/null)"
host_key_line="$(awk '$2 == "ssh-ed25519" {print $2, $3; exit}' <<<"$host_key")"
if [[ -z "$host_key_line" ]]; then
  echo "Failed to parse host SSH key" >&2
  exit 1
fi

host_key_type="ssh-ed25519"
host_key_value="$(awk '{print $2}' <<<"$host_key_line")"
jq -cn --arg ip "$ip_address" --arg key_type "$host_key_type" --arg key "$host_key_value" \
  '{ip: $ip, host_key: {type: $key_type, value: $key}}'

mkdir -p "$host_keys_dir"
printf '%s\n' "$host_key_line" > "$host_key_path"

pushd "${repo_root}/secrets" >/dev/null
agenix --rekey
popd >/dev/null

rm -rf "$host_dir"
cp -a "$host_template_post_dir" "$host_dir"
replace_hostname_placeholder "${host_dir}/configuration.nix" "$vm_name"

just finalize "${vm_name}" "${ip_address}"
popd >/dev/null
