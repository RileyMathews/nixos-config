#!/usr/bin/env python3
import argparse
import pathlib
import sys
import time
from typing import Any

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import proxmox_lib as proxmox
import proxmox_vm_common as vm_common


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Power-cycle a VM with deterministic shutdown -> stop -> start escalation."
    )
    parser.add_argument("vm", help="VMID or case-sensitive name fragment")
    parser.add_argument(
        "--soft-timeout",
        type=int,
        default=120,
        help="Seconds to wait for graceful shutdown before escalation",
    )
    parser.add_argument(
        "--start-timeout",
        type=int,
        default=120,
        help="Seconds to wait for VM to report running after start",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="If graceful shutdown times out, force stop and continue",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show intended actions without changing VM power state",
    )
    parser.add_argument("--yes", action="store_true", help="Skip confirmation prompt")
    parser.add_argument("--json", action="store_true", help="Print JSON output")
    return parser.parse_args()


def current_status(vm: dict[str, str]) -> str:
    status_json = proxmox.proxmox_get(
        f"/api2/json/nodes/{vm['node']}/qemu/{vm['vmid']}/status/current"
    )
    data = status_json.get("data", {})
    if not isinstance(data, dict):
        raise proxmox.ProxmoxError("Unexpected response while reading VM status")
    return str(data.get("status", "unknown"))


def wait_for_status(vm: dict[str, str], expected: str, timeout: int) -> bool:
    deadline = time.time() + max(1, timeout)
    while time.time() <= deadline:
        if current_status(vm) == expected:
            return True
        time.sleep(3)
    return current_status(vm) == expected


def power_cycle(vm: dict[str, str], args: argparse.Namespace) -> dict[str, Any]:
    initial_status = current_status(vm)
    steps: list[dict[str, Any]] = []

    if initial_status == "running":
        proxmox.proxmox_post_empty(
            f"/api2/json/nodes/{vm['node']}/qemu/{vm['vmid']}/status/shutdown"
        )
        steps.append({"action": "shutdown", "result": "requested"})

        if wait_for_status(vm, "stopped", args.soft_timeout):
            steps.append({"action": "shutdown", "result": "stopped"})
        else:
            if not args.force:
                raise proxmox.ProxmoxError(
                    "Timed out waiting for graceful shutdown; rerun with --force to escalate"
                )
            proxmox.proxmox_post_empty(
                f"/api2/json/nodes/{vm['node']}/qemu/{vm['vmid']}/status/stop"
            )
            steps.append({"action": "stop", "result": "requested"})
            if not wait_for_status(vm, "stopped", 60):
                raise proxmox.ProxmoxError("Timed out waiting for forced stop")
            steps.append({"action": "stop", "result": "stopped"})
    elif initial_status != "stopped":
        steps.append(
            {"action": "precheck", "result": f"initial_status={initial_status}"}
        )

    proxmox.proxmox_post_empty(
        f"/api2/json/nodes/{vm['node']}/qemu/{vm['vmid']}/status/start"
    )
    steps.append({"action": "start", "result": "requested"})

    if not wait_for_status(vm, "running", args.start_timeout):
        raise proxmox.ProxmoxError("Timed out waiting for VM to enter running state")
    steps.append({"action": "start", "result": "running"})

    return {
        "vmid": vm["vmid"],
        "name": vm["name"],
        "node": vm["node"],
        "initial_status": initial_status,
        "final_status": current_status(vm),
        "steps": steps,
    }


def print_summary(result: dict[str, Any]) -> None:
    print(
        f"Power cycle completed for {result['name']} (vmid {result['vmid']}, node {result['node']}): "
        f"{result['initial_status']} -> {result['final_status']}"
    )
    for step in result["steps"]:
        print(f"- {step['action']}: {step['result']}")


def main() -> None:
    args = parse_args()
    vm = vm_common.resolve_vm(args.vm)

    if not args.yes:
        confirm = input(
            f"Power cycle VM {vm['name']} (vmid {vm['vmid']}, node {vm['node']})? [y/N] "
        )
        if confirm.lower() != "y":
            print("Aborted.")
            return

    if args.dry_run:
        planned = {
            "vmid": vm["vmid"],
            "name": vm["name"],
            "node": vm["node"],
            "planned_steps": [
                "if running: shutdown",
                "if shutdown timeout and --force: stop",
                "start",
                "wait for running",
            ],
            "soft_timeout": args.soft_timeout,
            "start_timeout": args.start_timeout,
            "force": args.force,
        }
        if args.json:
            vm_common.print_json(planned)
        else:
            print(
                f"Dry run for {vm['name']} (vmid {vm['vmid']}, node {vm['node']}): "
                f"soft_timeout={args.soft_timeout}s start_timeout={args.start_timeout}s force={args.force}"
            )
            for step in planned["planned_steps"]:
                print(f"- {step}")
        return

    result = power_cycle(vm, args)

    if args.json:
        vm_common.print_json(result)
        return

    print_summary(result)


if __name__ == "__main__":
    try:
        main()
    except proxmox.ProxmoxError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
