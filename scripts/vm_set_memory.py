#!/usr/bin/env python3
import argparse
import pathlib
import sys

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import proxmox_lib as proxmox
import proxmox_vm_common as vm_common


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Update Proxmox VM memory config (MiB)."
    )
    parser.add_argument("vm", help="VMID or case-sensitive name fragment")
    parser.add_argument(
        "--memory-mib",
        type=int,
        required=True,
        help="Memory size in MiB (required)",
    )
    parser.add_argument(
        "--balloon-mib",
        type=int,
        help="Balloon memory in MiB (optional, 0 disables)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print intended changes without applying",
    )
    parser.add_argument("--json", action="store_true", help="Print JSON output")
    return parser.parse_args()


def validate_inputs(memory_mib: int, balloon_mib: int | None) -> None:
    if memory_mib <= 0:
        raise proxmox.ProxmoxError("memory-mib must be a positive integer")
    if balloon_mib is None:
        return
    if balloon_mib < 0:
        raise proxmox.ProxmoxError("balloon-mib must be zero or a positive integer")
    if balloon_mib > memory_mib:
        raise proxmox.ProxmoxError("balloon-mib cannot exceed memory-mib")


def main() -> None:
    args = parse_args()
    validate_inputs(args.memory_mib, args.balloon_mib)

    vm = vm_common.resolve_vm(args.vm)
    changes = [f"memory={args.memory_mib}"]
    if args.balloon_mib is not None:
        changes.append(f"balloon={args.balloon_mib}")

    if args.dry_run:
        payload = {
            "vmid": vm["vmid"],
            "name": vm["name"],
            "node": vm["node"],
            "changes": changes,
            "applied": False,
        }
        if args.json:
            vm_common.print_json(payload)
            return
        print(
            "Dry-run: would update memory for "
            f"{vm['name']} (vmid {vm['vmid']}, node {vm['node']}): "
            + ", ".join(changes)
        )
        return

    response = proxmox.proxmox_post_form(
        f"/api2/json/nodes/{vm['node']}/qemu/{vm['vmid']}/config",
        *changes,
    )

    payload = {
        "vmid": vm["vmid"],
        "name": vm["name"],
        "node": vm["node"],
        "changes": changes,
        "response": response,
        "applied": True,
    }

    if args.json:
        vm_common.print_json(payload)
        return

    print(
        f"Updated memory for {vm['name']} (vmid {vm['vmid']}, node {vm['node']}): "
        + ", ".join(changes)
    )


if __name__ == "__main__":
    try:
        main()
    except proxmox.ProxmoxError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
