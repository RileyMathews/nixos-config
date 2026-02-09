#!/usr/bin/env python3
import argparse
import json
import pathlib
import sys
from typing import Any

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import proxmox_lib as proxmox
import proxmox_vm_common as vm_common


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check guest-agent reachability and key calls for a Proxmox VM."
    )
    parser.add_argument("vm", help="VMID or case-sensitive name fragment")
    parser.add_argument("--json", action="store_true", help="Print JSON output")
    return parser.parse_args()


def call_raw(path: str) -> dict[str, Any]:
    status, body = proxmox.proxmox_get_raw(path)
    payload: Any = None
    if body:
        try:
            payload = json.loads(body)
        except json.JSONDecodeError:
            payload = body

    return {
        "http_status": status,
        "ok": status == 200,
        "payload": payload,
    }


def call_post(path: str) -> dict[str, Any]:
    try:
        payload = proxmox.proxmox_post_empty(path)
        return {"http_status": 200, "ok": True, "payload": payload}
    except proxmox.ProxmoxError as exc:
        return {"http_status": None, "ok": False, "payload": str(exc)}


def run_agent_checks(vm: dict[str, str]) -> dict[str, Any]:
    base = f"/api2/json/nodes/{vm['node']}/qemu/{vm['vmid']}/agent"
    ping = call_post(f"{base}/ping")
    interfaces = call_raw(f"{base}/network-get-interfaces")
    osinfo = call_raw(f"{base}/get-osinfo")

    primary_ipv4 = None
    if interfaces["ok"] and isinstance(interfaces["payload"], dict):
        primary_ipv4 = proxmox.first_ipv4_address(interfaces["payload"])

    return {
        "vmid": vm["vmid"],
        "name": vm["name"],
        "node": vm["node"],
        "checks": {
            "ping": ping,
            "network_get_interfaces": interfaces,
            "get_osinfo": osinfo,
        },
        "derived": {
            "healthy": bool(ping["ok"]),
            "primary_ipv4": primary_ipv4,
        },
    }


def print_summary(result: dict[str, Any]) -> None:
    checks = result["checks"]
    derived = result["derived"]
    print(
        f"VM {result['name']} (vmid {result['vmid']}, node {result['node']}): "
        f"agent_ping_ok={checks['ping']['ok']} "
        f"interfaces_ok={checks['network_get_interfaces']['ok']} "
        f"osinfo_ok={checks['get_osinfo']['ok']} "
        f"primary_ipv4={derived['primary_ipv4'] or 'n/a'}"
    )


def main() -> None:
    args = parse_args()
    vm = vm_common.resolve_vm(args.vm)
    result = run_agent_checks(vm)

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
