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
        description="Fetch runtime and config health indicators for a Proxmox VM."
    )
    parser.add_argument("vm", help="VMID or case-sensitive name fragment")
    parser.add_argument("--json", action="store_true", help="Print JSON output")
    return parser.parse_args()


def runtime_snapshot(vm: dict[str, str]) -> dict[str, Any]:
    status_json = proxmox.proxmox_get(
        f"/api2/json/nodes/{vm['node']}/qemu/{vm['vmid']}/status/current"
    )
    config_json = proxmox.proxmox_get(
        f"/api2/json/nodes/{vm['node']}/qemu/{vm['vmid']}/config"
    )

    status = status_json.get("data", {})
    config = config_json.get("data", {})
    if not isinstance(status, dict) or not isinstance(config, dict):
        raise proxmox.ProxmoxError("Unexpected response while fetching VM runtime data")

    mem = int(status.get("mem", 0) or 0)
    maxmem = int(status.get("maxmem", 0) or 0)
    mem_pct = (mem / maxmem) * 100 if maxmem > 0 else 0.0

    derived = {
        "running": status.get("status") == "running",
        "agent_enabled": vm_common.parse_bool_config(config.get("agent")),
        "onboot": vm_common.parse_bool_config(config.get("onboot")),
        "mem_percent": round(mem_pct, 1),
    }

    return {
        "vmid": vm["vmid"],
        "name": vm["name"],
        "node": vm["node"],
        "status": {
            "status": status.get("status", "unknown"),
            "qmpstatus": status.get("qmpstatus", "unknown"),
            "uptime": int(status.get("uptime", 0) or 0),
            "cpu_percent": round(float(status.get("cpu", 0.0) or 0.0) * 100, 1),
            "mem": mem,
            "maxmem": maxmem,
            "maxcpu": int(status.get("cpus", 0) or 0),
            "pid": int(status.get("pid", 0) or 0),
        },
        "config": {
            "agent": str(config.get("agent", "")),
            "onboot": str(config.get("onboot", "")),
            "boot": str(config.get("boot", "")),
            "machine": str(config.get("machine", "")),
            "ostype": str(config.get("ostype", "")),
            "scsihw": str(config.get("scsihw", "")),
        },
        "derived": derived,
    }


def print_summary(snapshot: dict[str, Any]) -> None:
    status = snapshot["status"]
    config = snapshot["config"]
    derived = snapshot["derived"]
    mem = status["mem"]
    maxmem = status["maxmem"]

    mem_text = f"{vm_common.human_bytes(mem)}/{vm_common.human_bytes(maxmem)}"
    if maxmem > 0:
        mem_text = f"{mem_text} ({derived['mem_percent']:.1f}%)"

    print(
        f"VM {snapshot['name']} (vmid {snapshot['vmid']}, node {snapshot['node']}): "
        f"{status['status']} qmp={status['qmpstatus']} uptime={vm_common.human_uptime(status['uptime'])} "
        f"cpu={status['cpu_percent']:.1f}% mem={mem_text} "
        f"agent_enabled={derived['agent_enabled']} onboot={derived['onboot']} machine={config['machine'] or 'unknown'}"
    )


def main() -> None:
    args = parse_args()
    vm = vm_common.resolve_vm(args.vm)
    snapshot = runtime_snapshot(vm)

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
