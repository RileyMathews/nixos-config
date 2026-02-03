#!/usr/bin/env python3
import os
import pathlib
import sys
import time

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import proxmox_lib as proxmox


def read_vmid() -> str:
    if len(sys.argv) != 2:
        raise proxmox.ProxmoxError(f"Usage: {sys.argv[0]} <vmid>")
    vmid = sys.argv[1]
    if not vmid.isdigit():
        raise proxmox.ProxmoxError("VMID must be a number")
    return vmid


def wait_for_shutdown(node: str, vmid: str) -> None:
    deadline_seconds = 300
    poll_interval_seconds = 5
    start_time = time.time()
    last_wait_log = 0.0

    while True:
        now = time.time()
        if now - start_time > deadline_seconds:
            raise proxmox.ProxmoxError("Timed out waiting for VM to shut down")

        if now - last_wait_log >= 15:
            print("Waiting for VM to shut down...", file=sys.stderr)
            last_wait_log = now

        status_json = proxmox.proxmox_get(
            f"/api2/json/nodes/{node}/qemu/{vmid}/status/current"
        )
        vm_status = status_json.get("data", {}).get("status", "")
        if vm_status == "stopped":
            return

        time.sleep(poll_interval_seconds)


def main() -> None:
    vmid = read_vmid()
    node = os.environ.get("PROXMOX_NODE", "shipyard")

    config_json = proxmox.proxmox_get(f"/api2/json/nodes/{node}/qemu/{vmid}/config")
    vm_name = config_json.get("data", {}).get("name", "") or "unknown"

    confirm = input(f"Delete VM {vm_name} (vmid {vmid})? [y/N] ")
    if confirm.lower() != "y":
        print("Aborted.")
        return

    proxmox.proxmox_post_empty(f"/api2/json/nodes/{node}/qemu/{vmid}/status/shutdown")

    wait_for_shutdown(node, vmid)

    proxmox.proxmox_delete(f"/api2/json/nodes/{node}/qemu/{vmid}")
    print(f"Deleted VM {vm_name} (vmid {vmid}).")


if __name__ == "__main__":
    try:
        main()
    except proxmox.ProxmoxError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
