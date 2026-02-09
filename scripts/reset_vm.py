#!/usr/bin/env python3
import os
import pathlib
import sys

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import proxmox_lib as proxmox


def read_args() -> tuple[str, bool]:
    args = sys.argv[1:]
    if not args:
        raise proxmox.ProxmoxError(f"Usage: {sys.argv[0]} [--yes] <vmid>")

    assume_yes = False
    vmid = ""

    for arg in args:
        if arg == "--yes":
            assume_yes = True
            continue

        if vmid:
            raise proxmox.ProxmoxError(f"Usage: {sys.argv[0]} [--yes] <vmid>")
        vmid = arg

    if not vmid:
        raise proxmox.ProxmoxError(f"Usage: {sys.argv[0]} [--yes] <vmid>")

    if not vmid.isdigit():
        raise proxmox.ProxmoxError("VMID must be a number")

    return vmid, assume_yes


def main() -> None:
    vmid, assume_yes = read_args()
    node = os.environ.get("PROXMOX_NODE", "shipyard")

    config_json = proxmox.proxmox_get(f"/api2/json/nodes/{node}/qemu/{vmid}/config")
    vm_name = config_json.get("data", {}).get("name", "") or "unknown"

    if not assume_yes:
        confirm = input(f"Reset VM {vm_name} (vmid {vmid})? [y/N] ")
        if confirm.lower() != "y":
            print("Aborted.")
            return

    proxmox.proxmox_post_empty(f"/api2/json/nodes/{node}/qemu/{vmid}/status/reset")
    print(f"Reset VM {vm_name} (vmid {vmid}).")


if __name__ == "__main__":
    try:
        main()
    except proxmox.ProxmoxError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
