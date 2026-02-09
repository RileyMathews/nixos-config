#!/usr/bin/env python3
import argparse
import pathlib
import sys
from typing import Any

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import proxmox_lib as proxmox
import proxmox_vm_common as vm_common


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Show host-node resource pressure for the VM's current node."
    )
    parser.add_argument("vm", help="VMID or case-sensitive name fragment")
    parser.add_argument("--json", action="store_true", help="Print JSON output")
    return parser.parse_args()


def node_snapshot(vm: dict[str, str]) -> dict[str, Any]:
    status_json = proxmox.proxmox_get(f"/api2/json/nodes/{vm['node']}/status")
    status = status_json.get("data", {})
    if not isinstance(status, dict):
        raise proxmox.ProxmoxError("Unexpected response while loading node status")

    memory = status.get("memory", {})
    rootfs = status.get("rootfs", {})
    if not isinstance(memory, dict):
        memory = {}
    if not isinstance(rootfs, dict):
        rootfs = {}

    mem_used = int(memory.get("used", 0) or 0)
    mem_total = int(memory.get("total", 0) or 0)
    mem_pct = (mem_used / mem_total) * 100 if mem_total > 0 else 0.0

    root_used = int(rootfs.get("used", 0) or 0)
    root_total = int(rootfs.get("total", 0) or 0)
    root_pct = (root_used / root_total) * 100 if root_total > 0 else 0.0

    loadavg = status.get("loadavg")
    if not isinstance(loadavg, list):
        loadavg = []

    return {
        "vmid": vm["vmid"],
        "name": vm["name"],
        "node": vm["node"],
        "node_status": {
            "cpu_percent": round(float(status.get("cpu", 0.0) or 0.0) * 100, 1),
            "uptime": int(status.get("uptime", 0) or 0),
            "memory_used": mem_used,
            "memory_total": mem_total,
            "memory_percent": round(mem_pct, 1),
            "rootfs_used": root_used,
            "rootfs_total": root_total,
            "rootfs_percent": round(root_pct, 1),
            "loadavg": loadavg,
        },
    }


def print_summary(snapshot: dict[str, Any]) -> None:
    node = snapshot["node_status"]
    loadavg = node["loadavg"]
    load_text = ",".join(str(x) for x in loadavg) if loadavg else "n/a"
    print(
        f"Node pressure for {snapshot['node']} (VM {snapshot['name']} vmid {snapshot['vmid']}): "
        f"cpu={node['cpu_percent']:.1f}% mem={vm_common.human_bytes(node['memory_used'])}/{vm_common.human_bytes(node['memory_total'])} ({node['memory_percent']:.1f}%) "
        f"rootfs={vm_common.human_bytes(node['rootfs_used'])}/{vm_common.human_bytes(node['rootfs_total'])} ({node['rootfs_percent']:.1f}%) "
        f"loadavg={load_text} uptime={vm_common.human_uptime(node['uptime'])}"
    )


def main() -> None:
    args = parse_args()
    vm = vm_common.resolve_vm(args.vm)
    snapshot = node_snapshot(vm)

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
