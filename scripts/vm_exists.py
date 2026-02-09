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
        description="Resolve and confirm a Proxmox QEMU VM exists by VMID or name fragment."
    )
    parser.add_argument("vm", help="VMID or case-sensitive name fragment")
    parser.add_argument("--json", action="store_true", help="Print JSON output")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    vm = vm_common.resolve_vm(args.vm)

    if args.json:
        vm_common.print_json({"exists": True, **vm})
        return

    print(f"VM exists: {vm['name']} (vmid {vm['vmid']}, node {vm['node']})")


if __name__ == "__main__":
    try:
        main()
    except proxmox.ProxmoxError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
