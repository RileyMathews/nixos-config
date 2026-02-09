#!/usr/bin/env python3
import argparse
import json
import os
import pathlib
import sys

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import proxmox_lib as proxmox


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Fetch current status for a Proxmox QEMU VM by VMID or name fragment."
    )
    parser.add_argument("vm", help="VMID or case-sensitive name fragment")
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print machine-readable JSON instead of a summary line",
    )
    return parser.parse_args()


def cluster_qemu_vms() -> list[dict]:
    resources_json = proxmox.proxmox_get("/api2/json/cluster/resources?type=vm")
    resources = resources_json.get("data", [])
    if not isinstance(resources, list):
        raise proxmox.ProxmoxError("Unexpected response while listing VMs")
    return [entry for entry in resources if entry.get("type") == "qemu"]


def resolve_vm(vm_query: str) -> tuple[str, str, str]:
    vms = cluster_qemu_vms()

    if vm_query.isdigit():
        for vm in vms:
            if str(vm.get("vmid", "")) == vm_query:
                return (
                    vm_query,
                    str(vm.get("name", "unknown")),
                    str(vm.get("node", "unknown")),
                )

        fallback_node = os.environ.get("PROXMOX_NODE", "shipyard")
        config_json = proxmox.proxmox_get(
            f"/api2/json/nodes/{fallback_node}/qemu/{vm_query}/config"
        )
        vm_name = config_json.get("data", {}).get("name", "") or "unknown"
        return vm_query, str(vm_name), fallback_node

    matches: list[dict] = []
    for vm in vms:
        name = vm.get("name")
        if isinstance(name, str) and vm_query in name:
            matches.append(vm)

    if not matches:
        raise proxmox.ProxmoxError(f"No QEMU VM name contains substring '{vm_query}'")

    if len(matches) > 1:
        print(
            f"Ambiguous query '{vm_query}': matched {len(matches)} QEMU VMs:",
            file=sys.stderr,
        )
        for vm in sorted(matches, key=lambda entry: str(entry.get("name", ""))):
            vmid = vm.get("vmid", "?")
            name = vm.get("name", "unknown")
            node = vm.get("node", "unknown")
            print(f"  vmid={vmid} name={name} node={node}", file=sys.stderr)
        raise proxmox.ProxmoxError("Refine your query to match exactly one VM")

    vm = matches[0]
    vmid = str(vm.get("vmid", ""))
    if not vmid.isdigit():
        raise proxmox.ProxmoxError("Match found but VMID is missing")
    return vmid, str(vm.get("name", "unknown")), str(vm.get("node", "unknown"))


def human_bytes(value: int) -> str:
    if value <= 0:
        return "0B"
    units = ["B", "KiB", "MiB", "GiB", "TiB"]
    size = float(value)
    for unit in units:
        if size < 1024 or unit == units[-1]:
            if unit == "B":
                return f"{int(size)}{unit}"
            return f"{size:.1f}{unit}"
        size /= 1024
    return f"{size:.1f}TiB"


def human_uptime(seconds: int) -> str:
    if seconds <= 0:
        return "0s"
    days, rem = divmod(seconds, 86400)
    hours, rem = divmod(rem, 3600)
    minutes, secs = divmod(rem, 60)

    parts: list[str] = []
    if days:
        parts.append(f"{days}d")
    if hours:
        parts.append(f"{hours}h")
    if minutes:
        parts.append(f"{minutes}m")
    if secs and not parts:
        parts.append(f"{secs}s")
    return "".join(parts)


def print_summary(vmid: str, name: str, node: str, status_data: dict) -> None:
    status = status_data.get("status", "unknown")
    uptime = int(status_data.get("uptime", 0) or 0)
    cpu = float(status_data.get("cpu", 0.0) or 0.0) * 100
    mem = int(status_data.get("mem", 0) or 0)
    maxmem = int(status_data.get("maxmem", 0) or 0)

    mem_part = f"{human_bytes(mem)}/{human_bytes(maxmem)}"
    if maxmem > 0:
        mem_part = f"{mem_part} ({(mem / maxmem) * 100:.1f}%)"

    print(
        f"VM {name} (vmid {vmid}, node {node}): {status} | "
        f"uptime {human_uptime(uptime)} | cpu {cpu:.1f}% | mem {mem_part}"
    )


def main() -> None:
    args = parse_args()
    vmid, name, node = resolve_vm(args.vm)
    status_json = proxmox.proxmox_get(
        f"/api2/json/nodes/{node}/qemu/{vmid}/status/current"
    )
    status_data = status_json.get("data", {})

    if not isinstance(status_data, dict):
        raise proxmox.ProxmoxError("Unexpected response while fetching VM status")

    if args.json:
        print(
            json.dumps(
                {
                    "vmid": vmid,
                    "name": name,
                    "node": node,
                    "status": status_data,
                },
                sort_keys=True,
            )
        )
        return

    print_summary(vmid, name, node, status_data)


if __name__ == "__main__":
    try:
        main()
    except proxmox.ProxmoxError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
