#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/proxmox-lib.sh"

require_cmd jq
require_cmd curl

PROXMOX_BASE_URL="https://shipyard:8006"
PROXMOX_NODE="shipyard"
PROXMOX_DEBUG="${PROXMOX_DEBUG:-1}"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <vmid>" >&2
  exit 1
fi

vmid="$1"
if [[ ! "$vmid" =~ ^[0-9]+$ ]]; then
  echo "VMID must be a number" >&2
  exit 1
fi

config_json="$(proxmox_get "/api2/json/nodes/${PROXMOX_NODE}/qemu/${vmid}/config")"
vm_name="$(jq -r '.data.name // empty' <<<"$config_json")"

if [[ -z "$vm_name" ]]; then
  vm_name="unknown"
fi

read -r -p "Delete VM ${vm_name} (vmid ${vmid})? [y/N] " confirm
case "$confirm" in
  y|Y) ;;
  *)
    echo "Aborted."
    exit 0
    ;;
esac

proxmox_post_empty "/api2/json/nodes/${PROXMOX_NODE}/qemu/${vmid}/status/shutdown"

deadline_seconds=300
poll_interval_seconds=5
start_time="$(date +%s)"
last_wait_log=0

while true; do
  now="$(date +%s)"
  if (( now - start_time > deadline_seconds )); then
    echo "Timed out waiting for VM to shut down" >&2
    exit 1
  fi

  if (( now - last_wait_log >= 15 )); then
    echo "Waiting for VM to shut down..." >&2
    last_wait_log="$now"
  fi

  status_json="$(proxmox_get "/api2/json/nodes/${PROXMOX_NODE}/qemu/${vmid}/status/current")"
  vm_status="$(jq -r '.data.status // empty' <<<"$status_json")"
  if [[ "$vm_status" == "stopped" ]]; then
    break
  fi

  sleep "$poll_interval_seconds"
done

proxmox_delete "/api2/json/nodes/${PROXMOX_NODE}/qemu/${vmid}"
echo "Deleted VM ${vm_name} (vmid ${vmid})."
