#!/usr/bin/env python3
import argparse
import pathlib
import re
import sys
from typing import Any

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import proxmox_lib as proxmox
import proxmox_vm_common as vm_common


DISK_KEY_PATTERN = re.compile(
    r"^(?:ide\d+|sata\d+|scsi\d+|virtio\d+|efidisk0|tpmstate0|unused\d+)$"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Inspect VM disk attachments and storage volume presence."
    )
    parser.add_argument("vm", help="VMID or case-sensitive name fragment")
    parser.add_argument("--json", action="store_true", help="Print JSON output")
    return parser.parse_args()


def parse_disk_value(raw: str) -> dict[str, str | None]:
    first = raw.split(",", 1)[0]
    if ":" not in first:
        return {"storage": None, "volume": None, "volid": None}
    storage, volume = first.split(":", 1)
    return {"storage": storage, "volume": volume, "volid": f"{storage}:{volume}"}


def storage_snapshot(vm: dict[str, str]) -> dict[str, Any]:
    config_json = proxmox.proxmox_get(
        f"/api2/json/nodes/{vm['node']}/qemu/{vm['vmid']}/config"
    )
    config = config_json.get("data", {})
    if not isinstance(config, dict):
        raise proxmox.ProxmoxError("Unexpected response while loading VM config")

    disks = []
    storages: set[str] = set()
    for key in sorted(config.keys()):
        value = config.get(key)
        if not isinstance(value, str) or not DISK_KEY_PATTERN.match(key):
            continue
        parsed = parse_disk_value(value)
        storage = parsed["storage"]
        if storage:
            storages.add(storage)
        disks.append(
            {
                "slot": key,
                "raw": value,
                **parsed,
            }
        )

    storage_index: dict[str, set[str] | None] = {}
    storage_errors: dict[str, str] = {}
    for storage in sorted(storages):
        try:
            content_json = proxmox.proxmox_get(
                f"/api2/json/nodes/{vm['node']}/storage/{storage}/content"
            )
            content = content_json.get("data", [])
            if not isinstance(content, list):
                storage_index[storage] = None
                storage_errors[storage] = "Unexpected storage content payload"
                continue
            storage_index[storage] = {
                str(entry.get("volid", "")) for entry in content if entry.get("volid")
            }
        except proxmox.ProxmoxError as exc:
            storage_index[storage] = None
            storage_errors[storage] = str(exc)

    for disk in disks:
        volid = disk.get("volid")
        storage = disk.get("storage")
        if not volid or not storage:
            disk["volume_present"] = None
            continue

        indexed = storage_index.get(str(storage))
        if indexed is None:
            disk["volume_present"] = None
            continue
        disk["volume_present"] = volid in indexed

    return {
        "vmid": vm["vmid"],
        "name": vm["name"],
        "node": vm["node"],
        "disks": disks,
        "storage_errors": storage_errors,
    }


def print_summary(snapshot: dict[str, Any]) -> None:
    print(
        f"Storage check for {snapshot['name']} (vmid {snapshot['vmid']}, node {snapshot['node']}):"
    )
    disks = snapshot["disks"]
    if not disks:
        print("- no disk-like config entries found")
        return

    for disk in disks:
        present = disk.get("volume_present")
        if present is True:
            present_text = "present"
        elif present is False:
            present_text = "missing"
        else:
            present_text = "unknown"

        print(
            f"- {disk['slot']} volid={disk.get('volid') or 'n/a'} "
            f"volume_present={present_text} raw={disk['raw']}"
        )

    if snapshot["storage_errors"]:
        print("Storage query issues:")
        for storage, err in snapshot["storage_errors"].items():
            print(f"- {storage}: {err}")


def main() -> None:
    args = parse_args()
    vm = vm_common.resolve_vm(args.vm)
    snapshot = storage_snapshot(vm)

    if args.json:
        vm_common.print_json(snapshot)
        return

    print_summary(snapshot)


if __name__ == "__main__":
    try:
        main()
    except proxmox.ProxmoxError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
