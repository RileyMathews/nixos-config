#!/usr/bin/env python3
import argparse
import json
import pathlib
import re
import subprocess
import sys
from typing import Any

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import proxmox_lib as proxmox
import proxmox_vm_common as vm_common


NET_KEY_PATTERN = re.compile(r"^net\d+$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Inspect VM NIC config and node bridge presence."
    )
    parser.add_argument("vm", help="VMID or case-sensitive name fragment")
    parser.add_argument(
        "--ping",
        action="store_true",
        help="Attempt ping to guest primary IPv4 (if guest agent reports one)",
    )
    parser.add_argument("--json", action="store_true", help="Print JSON output")
    return parser.parse_args()


def parse_net_value(raw: str) -> dict[str, Any]:
    parts = [part.strip() for part in raw.split(",") if part.strip()]
    if not parts:
        return {"raw": raw}

    model = "unknown"
    mac = None
    if "=" in parts[0]:
        first_k, first_v = parts[0].split("=", 1)
        model = first_k
        mac = first_v

    out: dict[str, Any] = {"raw": raw, "model": model, "mac": mac}
    for part in parts[1:]:
        if "=" in part:
            key, value = part.split("=", 1)
            out[key] = value
        else:
            out[part] = True
    return out


def load_guest_primary_ipv4(vm: dict[str, str]) -> str | None:
    status, body = proxmox.proxmox_get_raw(
        f"/api2/json/nodes/{vm['node']}/qemu/{vm['vmid']}/agent/network-get-interfaces"
    )
    if status != 200:
        return None

    try:
        payload = json.loads(body)
    except json.JSONDecodeError:
        return None

    if not isinstance(payload, dict):
        return None
    return proxmox.first_ipv4_address(payload)


def ping_once(ip_address: str) -> bool:
    result = subprocess.run(
        ["ping", "-c", "1", "-W", "2", ip_address],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0


def net_snapshot(vm: dict[str, str], do_ping: bool) -> dict[str, Any]:
    config_json = proxmox.proxmox_get(
        f"/api2/json/nodes/{vm['node']}/qemu/{vm['vmid']}/config"
    )
    config = config_json.get("data", {})
    if not isinstance(config, dict):
        raise proxmox.ProxmoxError("Unexpected response while loading VM config")

    node_net_json = proxmox.proxmox_get(f"/api2/json/nodes/{vm['node']}/network")
    node_ifaces = node_net_json.get("data", [])
    if not isinstance(node_ifaces, list):
        raise proxmox.ProxmoxError("Unexpected response while loading node network")

    iface_names = {
        str(entry.get("iface", "")) for entry in node_ifaces if entry.get("iface")
    }

    nics = []
    for key in sorted(config.keys()):
        value = config.get(key)
        if not isinstance(value, str) or not NET_KEY_PATTERN.match(key):
            continue

        parsed = parse_net_value(value)
        bridge = parsed.get("bridge")
        nics.append(
            {
                "slot": key,
                **parsed,
                "bridge_present_on_node": bool(bridge and bridge in iface_names),
            }
        )

    primary_ipv4 = load_guest_primary_ipv4(vm)
    ping_ok = ping_once(primary_ipv4) if (do_ping and primary_ipv4) else None

    return {
        "vmid": vm["vmid"],
        "name": vm["name"],
        "node": vm["node"],
        "nics": nics,
        "derived": {
            "primary_ipv4": primary_ipv4,
            "ping_ok": ping_ok,
            "known_node_ifaces": sorted(iface_names),
        },
    }


def print_summary(snapshot: dict[str, Any]) -> None:
    derived = snapshot["derived"]
    print(
        f"Network check for {snapshot['name']} (vmid {snapshot['vmid']}, node {snapshot['node']}): "
        f"primary_ipv4={derived['primary_ipv4'] or 'n/a'} ping_ok={derived['ping_ok']}"
    )

    for nic in snapshot["nics"]:
        print(
            f"- {nic['slot']} model={nic.get('model', 'unknown')} mac={nic.get('mac', 'unknown')} "
            f"bridge={nic.get('bridge', 'n/a')} bridge_present={nic['bridge_present_on_node']} raw={nic['raw']}"
        )


def main() -> None:
    args = parse_args()
    vm = vm_common.resolve_vm(args.vm)
    snapshot = net_snapshot(vm, args.ping)

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
