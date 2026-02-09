#!/usr/bin/env python3
import pathlib
import sys

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import proxmox_lib as proxmox


def read_query() -> str:
    if len(sys.argv) != 2:
        raise proxmox.ProxmoxError(f"Usage: {sys.argv[0]} <name-fragment>")

    query = sys.argv[1].strip()
    if not query:
        raise proxmox.ProxmoxError("Name fragment must not be empty")
    return query


def find_qemu_vm_matches(name_fragment: str) -> list[dict]:
    resources_json = proxmox.proxmox_get("/api2/json/cluster/resources?type=vm")
    resources = resources_json.get("data", [])
    if not isinstance(resources, list):
        raise proxmox.ProxmoxError("Unexpected response while listing VMs")

    matches: list[dict] = []
    for vm in resources:
        if vm.get("type") != "qemu":
            continue

        name = vm.get("name")
        if not isinstance(name, str):
            continue

        if name_fragment in name:
            matches.append(vm)

    return matches


def main() -> None:
    name_fragment = read_query()
    matches = find_qemu_vm_matches(name_fragment)

    if not matches:
        raise proxmox.ProxmoxError(
            f"No QEMU VM name contains substring '{name_fragment}'"
        )

    if len(matches) == 1:
        vmid = matches[0].get("vmid")
        if vmid is None:
            raise proxmox.ProxmoxError("Match found but VMID is missing")
        print(str(vmid))
        return

    print(
        f"Ambiguous query '{name_fragment}': matched {len(matches)} QEMU VMs:",
        file=sys.stderr,
    )
    for vm in sorted(matches, key=lambda entry: str(entry.get("name", ""))):
        vmid = vm.get("vmid", "?")
        name = vm.get("name", "unknown")
        node = vm.get("node", "unknown")
        print(f"  vmid={vmid} name={name} node={node}", file=sys.stderr)

    raise proxmox.ProxmoxError("Refine your query to match exactly one VM")


if __name__ == "__main__":
    try:
        main()
    except proxmox.ProxmoxError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
