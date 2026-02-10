#!/usr/bin/env python3
import json
import os
import pathlib
import sys
from typing import Any

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import proxmox_lib as proxmox


def list_qemu_vms() -> list[dict[str, Any]]:
    resources_json = proxmox.proxmox_get("/api2/json/cluster/resources?type=vm")
    resources = resources_json.get("data", [])
    if not isinstance(resources, list):
        raise proxmox.ProxmoxError("Unexpected response while listing VMs")
    return [entry for entry in resources if entry.get("type") == "qemu"]


def resolve_vm(vm_query: str) -> dict[str, str]:
    if not vm_query:
        raise proxmox.ProxmoxError("VM query must not be empty")

    vms = list_qemu_vms()

    if vm_query.isdigit():
        for vm in vms:
            if str(vm.get("vmid", "")) == vm_query:
                return {
                    "vmid": vm_query,
                    "name": str(vm.get("name", "unknown")),
                    "node": str(vm.get("node", "unknown")),
                }
        raise proxmox.ProxmoxError(f"No QEMU VM found with VMID '{vm_query}'")

    matches: list[dict[str, Any]] = []
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

    return {
        "vmid": vmid,
        "name": str(vm.get("name", "unknown")),
        "node": str(vm.get("node", "unknown")),
    }


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


def parse_bool_config(value: Any) -> bool:
    if value is None:
        return False

    text = str(value).strip().lower()
    if text in {"0", "false", "no", "off"}:
        return False
    if text in {"1", "true", "yes", "on"}:
        return True

    for part in text.split(","):
        if part.startswith("enabled="):
            return part.split("=", 1)[1] in {"1", "true", "yes", "on"}
    return True


def print_json(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, sort_keys=True))


def default_node() -> str:
    return os.environ.get("PROXMOX_NODE", "shipyard")
