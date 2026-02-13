#!/usr/bin/env python3
import argparse
import pathlib
import sys

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import proxmox_lib as proxmox
import proxmox_vm_common as vm_common


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Update Proxmox VM CPU config.")
    parser.add_argument("vm", help="VMID or case-sensitive name fragment")
    parser.add_argument("--cores", type=int, help="CPU cores per socket")
    parser.add_argument("--sockets", type=int, help="CPU socket count")
    parser.add_argument("--vcpus", type=int, help="Maximum vCPU count")
    parser.add_argument(
        "--cpu-type",
        help="CPU type string (ex: host, x86-64-v2-AES)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print intended changes without applying",
    )
    parser.add_argument("--json", action="store_true", help="Print JSON output")
    return parser.parse_args()


def validate_positive(value: int | None, label: str) -> None:
    if value is None:
        return
    if value <= 0:
        raise proxmox.ProxmoxError(f"{label} must be a positive integer")


def build_changes(args: argparse.Namespace) -> list[str]:
    changes: list[str] = []
    if args.cores is not None:
        changes.append(f"cores={args.cores}")
    if args.sockets is not None:
        changes.append(f"sockets={args.sockets}")
    if args.vcpus is not None:
        changes.append(f"vcpus={args.vcpus}")
    if args.cpu_type:
        changes.append(f"cpu={args.cpu_type}")
    if not changes:
        raise proxmox.ProxmoxError(
            "At least one of --cores, --sockets, --vcpus, or --cpu-type is required"
        )
    return changes


def main() -> None:
    args = parse_args()
    validate_positive(args.cores, "cores")
    validate_positive(args.sockets, "sockets")
    validate_positive(args.vcpus, "vcpus")

    changes = build_changes(args)
    vm = vm_common.resolve_vm(args.vm)

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
            "Dry-run: would update CPU for "
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
        f"Updated CPU config for {vm['name']} (vmid {vm['vmid']}, node {vm['node']}): "
        + ", ".join(changes)
    )


if __name__ == "__main__":
    try:
        main()
    except proxmox.ProxmoxError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
