#!/usr/bin/env python3
import json
import os
import pathlib
import shutil
import subprocess
import sys
import time

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import proxmox_lib as proxmox


def ensure_required_commands() -> None:
    proxmox.require_cmd("just")
    proxmox.require_cmd("agenix")
    proxmox.require_cmd("ping")
    proxmox.require_cmd("ssh-keyscan")
    proxmox.require_cmd("git")


def run_just(args: list[str], repo_root: pathlib.Path) -> None:
    proxmox.run_command(["just", *args], cwd=repo_root)


def run_git_add(args: list[str], repo_root: pathlib.Path) -> None:
    proxmox.run_command(["git", "add", *args], cwd=repo_root)


def read_vm_name() -> str:
    if len(sys.argv) != 2:
        raise proxmox.ProxmoxError(f"Usage: {sys.argv[0]} <vm-name>")
    return sys.argv[1]


def wait_for_guest_ip(node: str, vmid: str) -> str:
    deadline_seconds = 300
    poll_interval_seconds = 5
    start_time = time.time()
    last_wait_log = 0.0

    while True:
        now = time.time()
        if now - start_time > deadline_seconds:
            raise proxmox.ProxmoxError("Timed out waiting for guest agent IP")

        if now - last_wait_log >= 15:
            print("Waiting for guest agent IP...", file=sys.stderr)
            last_wait_log = now

        status, body = proxmox.proxmox_get_raw(
            f"/api2/json/nodes/{node}/qemu/{vmid}/agent/network-get-interfaces"
        )
        if status != 200:
            time.sleep(poll_interval_seconds)
            continue

        try:
            interfaces_json = json.loads(body)
        except json.JSONDecodeError:
            time.sleep(poll_interval_seconds)
            continue

        ip_address = proxmox.first_ipv4_address(interfaces_json)
        if ip_address:
            return ip_address

        time.sleep(poll_interval_seconds)


def wait_for_ping(ip_address: str) -> None:
    deadline_seconds = 300
    poll_interval_seconds = 5
    start_time = time.time()
    last_wait_log = 0.0

    while True:
        now = time.time()
        if now - start_time > deadline_seconds:
            raise proxmox.ProxmoxError(
                "Timed out waiting for host to respond to ping after provision"
            )

        if now - last_wait_log >= 15:
            print(
                "Waiting for host to respond to ping after provision...",
                file=sys.stderr,
            )
            last_wait_log = now

        result = subprocess.run(
            ["ping", "-c", "1", "-W", "2", ip_address],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if result.returncode == 0:
            return

        time.sleep(poll_interval_seconds)


def fetch_host_key(ip_address: str) -> str:
    result = subprocess.run(
        ["ssh-keyscan", "-t", "ed25519", ip_address],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        check=False,
    )
    for line in result.stdout.splitlines():
        parts = line.split()
        if len(parts) >= 3 and parts[1] == "ssh-ed25519":
            return f"{parts[1]} {parts[2]}"
    raise proxmox.ProxmoxError("Failed to parse host SSH key")


def main() -> None:
    ensure_required_commands()
    vm_name = read_vm_name()

    repo_root = SCRIPT_DIR.parent
    hosts_dir = repo_root / "hosts"
    host_dir = hosts_dir / vm_name
    host_template_pre_dir = hosts_dir / "template-pre"
    host_template_post_dir = hosts_dir / "template-post"
    host_keys_dir = repo_root / "secrets" / "host-keys"
    host_key_path = host_keys_dir / f"{vm_name}.pub"

    if host_dir.exists():
        raise proxmox.ProxmoxError(f"Host directory already exists at {host_dir}")

    if host_key_path.exists():
        raise proxmox.ProxmoxError(f"Host key already exists at {host_key_path}")

    if not host_template_pre_dir.is_dir():
        raise proxmox.ProxmoxError(
            f"Host pre-provision template directory not found at {host_template_pre_dir}"
        )

    if not host_template_post_dir.is_dir():
        raise proxmox.ProxmoxError(
            f"Host post-provision template directory not found at {host_template_post_dir}"
        )

    shutil.copytree(host_template_pre_dir, host_dir)
    proxmox.replace_hostname_placeholder(host_dir / "configuration.nix", vm_name)
    run_git_add([str(host_dir)], repo_root)

    run_just(["build-iso"], repo_root)

    result_path = (repo_root / "result").resolve()
    iso_dir = result_path / "iso"
    iso_candidates = list(iso_dir.glob("*.iso"))
    if not iso_candidates:
        raise proxmox.ProxmoxError(f"ISO not found under {iso_dir}")

    iso_path = iso_candidates[0]
    upload_name = f"{vm_name}.iso"

    node = os.environ.get("PROXMOX_NODE", "shipyard")
    storage = os.environ.get("PROXMOX_STORAGE", "local")
    disk_storage = os.environ.get("PROXMOX_DISK_STORAGE", "nvme")

    proxmox.proxmox_upload_iso(
        f"/api2/json/nodes/{node}/storage/{storage}/upload",
        iso_path,
        upload_name,
    )

    nextid_json = proxmox.proxmox_get("/api2/json/cluster/nextid")
    nextid = str(nextid_json.get("data", "")).strip()
    if not nextid.isdigit():
        raise proxmox.ProxmoxError("Failed to parse next VMID")

    proxmox.proxmox_post_form(
        f"/api2/json/nodes/{node}/qemu",
        f"vmid={nextid}",
        f"name={vm_name}",
        "memory=2048",
        "sockets=1",
        "cores=1",
        "agent=1",
        "scsihw=virtio-scsi-pci",
        f"scsi0={disk_storage}:32,discard=on",
        f"ide2={storage}:iso/{upload_name},media=cdrom",
        "boot=order=scsi0;ide2;net0",
        "net0=virtio,bridge=vmbr0",
    )

    proxmox.proxmox_post_empty(f"/api2/json/nodes/{node}/qemu/{nextid}/status/start")

    ip_address = wait_for_guest_ip(node, nextid)

    run_just(["provision", f".#{vm_name}", ip_address], repo_root)

    wait_for_ping(ip_address)

    host_key_line = fetch_host_key(ip_address)
    host_key_type = "ssh-ed25519"
    host_key_value = host_key_line.split()[1]

    output = {
        "ip": ip_address,
        "host_key": {"type": host_key_type, "value": host_key_value},
    }
    print(json.dumps(output))

    host_keys_dir.mkdir(parents=True, exist_ok=True)
    host_key_path.write_text(f"{host_key_line}\n", encoding="utf-8")
    run_git_add([str(host_keys_dir)], repo_root)

    secrets_dir = repo_root / "secrets"
    proxmox.run_command(["agenix", "--rekey"], cwd=secrets_dir)

    shutil.rmtree(host_dir)
    shutil.copytree(host_template_post_dir, host_dir)
    proxmox.replace_hostname_placeholder(host_dir / "configuration.nix", vm_name)
    run_git_add([str(host_dir)], repo_root)

    run_just(["finalize", vm_name, ip_address], repo_root)


if __name__ == "__main__":
    try:
        main()
    except proxmox.ProxmoxError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
