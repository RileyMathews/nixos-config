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
        description="Inspect lock state and running tasks for a Proxmox VM."
    )
    parser.add_argument("vm", help="VMID or case-sensitive name fragment")
    parser.add_argument("--json", action="store_true", help="Print JSON output")
    return parser.parse_args()


def lock_snapshot(vm: dict[str, str]) -> dict[str, Any]:
    config_json = proxmox.proxmox_get(
        f"/api2/json/nodes/{vm['node']}/qemu/{vm['vmid']}/config"
    )
    status_json = proxmox.proxmox_get(
        f"/api2/json/nodes/{vm['node']}/qemu/{vm['vmid']}/status/current"
    )
    tasks_json = proxmox.proxmox_get(
        f"/api2/json/nodes/{vm['node']}/tasks?vmid={vm['vmid']}&limit=20"
    )

    config = config_json.get("data", {})
    status = status_json.get("data", {})
    tasks = tasks_json.get("data", [])
    if (
        not isinstance(config, dict)
        or not isinstance(status, dict)
        or not isinstance(tasks, list)
    ):
        raise proxmox.ProxmoxError("Unexpected response while checking VM locks")

    running_tasks = []
    for task in tasks:
        task_status = str(task.get("status", "running"))
        if task_status.lower() == "running":
            running_tasks.append(task)

    lock_value = config.get("lock")
    return {
        "vmid": vm["vmid"],
        "name": vm["name"],
        "node": vm["node"],
        "lock": str(lock_value) if lock_value is not None else None,
        "status": str(status.get("status", "unknown")),
        "qmpstatus": str(status.get("qmpstatus", "unknown")),
        "ha_state": str(status.get("ha", "")),
        "running_tasks": running_tasks,
        "derived": {
            "locked": lock_value is not None,
            "running_task_count": len(running_tasks),
        },
    }


def print_summary(snapshot: dict[str, Any]) -> None:
    lock_text = snapshot["lock"] if snapshot["lock"] else "none"
    print(
        f"VM {snapshot['name']} (vmid {snapshot['vmid']}, node {snapshot['node']}): "
        f"lock={lock_text} status={snapshot['status']} qmp={snapshot['qmpstatus']} "
        f"running_tasks={snapshot['derived']['running_task_count']}"
    )
    for task in snapshot["running_tasks"]:
        print(
            f"- running type={task.get('type', 'unknown')} upid={task.get('upid', '?')} "
            f"user={task.get('user', 'unknown')}"
        )


def main() -> None:
    args = parse_args()
    vm = vm_common.resolve_vm(args.vm)
    snapshot = lock_snapshot(vm)

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
