#!/usr/bin/env python3
import json
import os
import pathlib
import shutil
import sys
from typing import Any, Iterable, Tuple

import subprocess

import requests
import urllib3


urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class ProxmoxError(RuntimeError):
    pass


def require_cmd(cmd: str) -> None:
    if shutil.which(cmd) is None:
        raise ProxmoxError(f"{cmd} is required but was not found in PATH")


def replace_hostname_placeholder(config_path: pathlib.Path, hostname: str) -> None:
    if not config_path.is_file():
        raise ProxmoxError(f"Missing configuration.nix at {config_path}")

    contents = config_path.read_text(encoding="utf-8")
    if "{{template}}" not in contents:
        raise ProxmoxError(
            f"Expected hostname placeholder {{template}} not found in {config_path}"
        )

    config_path.write_text(contents.replace("{{template}}", hostname), encoding="utf-8")


def _proxmox_headers() -> dict:
    token = os.environ.get("PROXMOX_API_TOKEN")
    if not token:
        raise ProxmoxError("PROXMOX_API_TOKEN is not set")
    return {"Authorization": (f"PVEAPIToken=root@pam!ds9-nixos-repo-token={token}")}


def _proxmox_base_url() -> str:
    return os.environ.get("PROXMOX_BASE_URL", "https://shipyard:8006")


def _proxmox_debug_enabled() -> bool:
    return os.environ.get("PROXMOX_DEBUG", "1") == "1"


def _proxmox_request(
    method: str,
    path: str,
    *,
    data: dict | None = None,
    json_body: dict | None = None,
    files: dict | None = None,
) -> Any:
    if not path or not path.startswith("/"):
        raise ProxmoxError("Endpoint path must start with /")

    url = f"{_proxmox_base_url()}{path}"
    headers = _proxmox_headers()
    if json_body is not None:
        headers["Content-Type"] = "application/json"

    response = requests.request(
        method,
        url,
        headers=headers,
        data=data,
        json=json_body,
        files=files,
        verify=False,
    )

    if _proxmox_debug_enabled():
        print(
            f"[DEBUG] {method} {path} -> HTTP {response.status_code}", file=sys.stderr
        )
        if response.text:
            print(f"[DEBUG] Response: {response.text}", file=sys.stderr)

    if response.status_code != 200:
        message = f"Request failed with HTTP {response.status_code}"
        if response.text:
            message = f"{message}\n{response.text}"
        raise ProxmoxError(message)

    if response.text:
        try:
            return response.json()
        except json.JSONDecodeError:
            return response.text
    return None


def proxmox_get(path: str) -> Any:
    return _proxmox_request("GET", path)


def proxmox_post(path: str, json_body: dict) -> Any:
    return _proxmox_request("POST", path, json_body=json_body)


def proxmox_post_empty(path: str) -> Any:
    return _proxmox_request("POST", path)


def proxmox_post_form(path: str, *kv_pairs: str) -> Any:
    data: dict[str, str] = {}
    for kv in kv_pairs:
        if "=" not in kv:
            raise ProxmoxError(f"Invalid form pair: {kv}")
        key, value = kv.split("=", 1)
        data[key] = value
    return _proxmox_request("POST", path, data=data)


def proxmox_delete(path: str) -> Any:
    return _proxmox_request("DELETE", path)


def proxmox_get_raw(path: str) -> Tuple[int, str]:
    if not path or not path.startswith("/"):
        raise ProxmoxError("Endpoint path must start with /")

    url = f"{_proxmox_base_url()}{path}"
    headers = _proxmox_headers()
    response = requests.get(url, headers=headers, verify=False)

    if _proxmox_debug_enabled():
        print(
            f"[DEBUG] GET {path} (raw) -> HTTP {response.status_code}", file=sys.stderr
        )
        if response.text:
            print(f"[DEBUG] Response: {response.text}", file=sys.stderr)

    return response.status_code, response.text


def proxmox_upload_iso(path: str, file_path: pathlib.Path, upload_name: str) -> Any:
    if not file_path.is_file():
        raise ProxmoxError(f"ISO not found at {file_path}")

    files = {
        "content": (None, "iso"),
        "filename": (upload_name, file_path.read_bytes()),
    }
    return _proxmox_request("POST", path, files=files)


def first_ipv4_address(interfaces_json: dict) -> str | None:
    data = interfaces_json.get("data", {})
    for iface in data.get("result", []):
        for ip_info in iface.get("ip-addresses", []) or []:
            if ip_info.get("ip-address-type") != "ipv4":
                continue
            ip_address = ip_info.get("ip-address")
            if not ip_address:
                continue
            if ip_address == "127.0.0.1":
                continue
            if ip_address.startswith("169.254."):
                continue
            return ip_address
    return None


def run_command(args: Iterable[str], *, cwd: pathlib.Path | None = None) -> None:
    subprocess.run(list(args), cwd=cwd, check=True)
