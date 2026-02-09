#!/usr/bin/env python3
import argparse
import pathlib
import sys
from urllib.parse import quote

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import proxmox_lib as proxmox
import proxmox_vm_common as vm_common


QEMU_TASK_TYPES = {
    "qmstart",
    "qmstop",
    "qmshutdown",
    "qmreboot",
    "qmreset",
    "qmsuspend",
    "qmresume",
    "vzdump",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Show tail of the most recent VM-related Proxmox task log "
            "as a console-adjacent troubleshooting signal."
        )
    )
    parser.add_argument("vm", help="VMID or case-sensitive name fragment")
    parser.add_argument("--lines", type=int, default=40, help="Number of lines to show")
    parser.add_argument("--json", action="store_true", help="Print JSON output")
    return parser.parse_args()


def latest_task_with_log(vm: dict[str, str]) -> dict | None:
    tasks_json = proxmox.proxmox_get(
        f"/api2/json/nodes/{vm['node']}/tasks?vmid={vm['vmid']}&limit=50"
    )
    tasks = tasks_json.get("data", [])
    if not isinstance(tasks, list):
        raise proxmox.ProxmoxError("Unexpected response while listing tasks")

    for task in tasks:
        if str(task.get("type", "")) in QEMU_TASK_TYPES and task.get("upid"):
            return task
    return None


def task_log(node: str, upid: str) -> list[dict]:
    encoded_upid = quote(upid, safe="")
    log_json = proxmox.proxmox_get(f"/api2/json/nodes/{node}/tasks/{encoded_upid}/log")
    entries = log_json.get("data", [])
    if not isinstance(entries, list):
        raise proxmox.ProxmoxError("Unexpected response while fetching task log")
    return entries


def main() -> None:
    args = parse_args()
    vm = vm_common.resolve_vm(args.vm)
    task = latest_task_with_log(vm)

    if not task:
        payload = {
            "vmid": vm["vmid"],
            "name": vm["name"],
            "node": vm["node"],
            "task": None,
            "lines": [],
            "note": "No recent VM task logs found.",
        }
        if args.json:
            vm_common.print_json(payload)
        else:
            print(
                f"VM {vm['name']} (vmid {vm['vmid']}, node {vm['node']}): no recent VM task logs found"
            )
        return

    upid = str(task.get("upid"))
    node = str(task.get("node", vm["node"]))
    entries = task_log(node, upid)
    line_count = max(1, min(args.lines, 500))
    tail = entries[-line_count:]
    lines = [str(entry.get("t", "")) for entry in tail]

    payload = {
        "vmid": vm["vmid"],
        "name": vm["name"],
        "node": vm["node"],
        "task": {
            "upid": upid,
            "type": str(task.get("type", "unknown")),
            "status": str(task.get("status", "unknown")),
            "node": node,
        },
        "lines": lines,
        "note": (
            "Proxmox API does not expose a direct live guest serial console tail for QEMU; "
            "this is the latest VM-related task log tail."
        ),
    }

    if args.json:
        vm_common.print_json(payload)
        return

    print(
        f"VM {vm['name']} (vmid {vm['vmid']}, node {vm['node']}): "
        f"latest_task={payload['task']['type']} status={payload['task']['status']} upid={upid}"
    )
    print(payload["note"])
    for line in lines:
        print(f"- {line}")


if __name__ == "__main__":
    try:
        main()
    except proxmox.ProxmoxError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
