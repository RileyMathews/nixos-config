#!/usr/bin/env python3
import argparse
import pathlib
import sys
from datetime import datetime, timezone
from typing import Any

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import proxmox_lib as proxmox
import proxmox_vm_common as vm_common


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="List recent Proxmox tasks related to a VM."
    )
    parser.add_argument("vm", help="VMID or case-sensitive name fragment")
    parser.add_argument(
        "--limit", type=int, default=10, help="Max task rows (default: 10)"
    )
    parser.add_argument("--json", action="store_true", help="Print JSON output")
    return parser.parse_args()


def ts_to_text(value: Any) -> str:
    if value in (None, ""):
        return "-"
    try:
        dt = datetime.fromtimestamp(int(value), tz=timezone.utc)
        return dt.strftime("%Y-%m-%dT%H:%M:%SZ")
    except (ValueError, TypeError):
        return str(value)


def load_tasks(vm: dict[str, str], limit: int) -> list[dict[str, Any]]:
    safe_limit = max(1, min(limit, 100))
    node_path = (
        f"/api2/json/nodes/{vm['node']}/tasks?vmid={vm['vmid']}&limit={safe_limit}"
    )
    tasks_json = proxmox.proxmox_get(node_path)

    tasks = tasks_json.get("data", [])
    if not isinstance(tasks, list):
        raise proxmox.ProxmoxError("Unexpected response while listing tasks")
    return tasks


def print_summary(vm: dict[str, str], tasks: list[dict[str, Any]]) -> None:
    print(f"Recent tasks for {vm['name']} (vmid {vm['vmid']}, node {vm['node']}):")
    if not tasks:
        print("- none")
        return

    for task in tasks:
        upid = str(task.get("upid", "?"))
        task_type = str(task.get("type", "unknown"))
        status = str(task.get("status", "running"))
        user = str(task.get("user", "unknown"))
        start = ts_to_text(task.get("starttime"))
        end = ts_to_text(task.get("endtime"))
        print(
            f"- {task_type} status={status} user={user} start={start} end={end} upid={upid}"
        )


def main() -> None:
    args = parse_args()
    vm = vm_common.resolve_vm(args.vm)
    tasks = load_tasks(vm, args.limit)

    if args.json:
        vm_common.print_json(
            {
                "vmid": vm["vmid"],
                "name": vm["name"],
                "node": vm["node"],
                "tasks": tasks,
            }
        )
        return

    print_summary(vm, tasks)


if __name__ == "__main__":
    try:
        main()
    except proxmox.ProxmoxError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
