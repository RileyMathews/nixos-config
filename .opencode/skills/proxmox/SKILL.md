---
name: proxmox
description: Use when investigating or interacting with Proxmox VE, shipyard, pvesh, the Proxmox API, VMs, LXC containers, Proxmox storage, or homelab host diagnostics.
---

# Proxmox VE

Use this skill when the user asks about Proxmox, `shipyard`, VM/LXC inventory, Proxmox storage, API discovery, or diagnostics on homelab VMs.

## Environment

- The Proxmox VE host is `shipyard` and is reachable by its Tailscale name.
- Prefer SSH for diagnostics: `ssh root@shipyard ...`.
- Do not deploy hosts or apply Proxmox-changing actions unless the user explicitly asks for that specific change.
- Default to read-only commands first. Avoid creating, deleting, migrating, rebooting, stopping, starting, resizing, or reconfiguring VMs/LXCs/storage/users/tokens unless explicitly requested.

## API Discovery

Proxmox does not expose a built-in OpenAPI or Swagger spec. It has its own API schema based on JSON Schema.

Useful built-in docs on `shipyard`:

```text
https://shipyard:8006/pve-docs/api-viewer/index.html
https://shipyard:8006/pve-docs/api-viewer/apidoc.js
```

`apidoc.js` contains a JavaScript assignment like this:

```js
const apiSchema = [...]
```

That array is the machine-readable API tree used by the Proxmox API viewer. It includes endpoint paths, methods, descriptions, parameter schemas, return schemas, permissions, and token support.

Known non-endpoints checked on `shipyard`:

```text
/openapi.json
/swagger.json
/openapi
/swagger
```

These are not Proxmox API handlers.

## Parsing `apidoc.js`

Use this pattern to inspect the API schema without saving credentials:

```bash
python3 - <<'PY'
import json, ssl, urllib.request

url = 'https://shipyard:8006/pve-docs/api-viewer/apidoc.js'
ctx = ssl._create_unverified_context()
text = urllib.request.urlopen(url, context=ctx, timeout=10).read().decode()

prefix = 'const apiSchema = '
pos = text.index(prefix) + len(prefix)
schema, _ = json.JSONDecoder().raw_decode(text[pos:])

paths = []
def walk(nodes):
    for node in nodes:
        if 'path' in node:
            paths.append((node['path'], sorted((node.get('info') or {}).keys())))
        walk(node.get('children') or [])

walk(schema)
print(f'documented paths: {len(paths)}')
for path, methods in paths[:20]:
    print(path, methods)
PY
```

Useful paths to search for in the parsed schema:

```text
/version
/cluster/resources
/nodes
/nodes/{node}/qemu
/nodes/{node}/qemu/{vmid}/config
/nodes/{node}/qemu/{vmid}/status/current
/nodes/{node}/lxc
/nodes/{node}/lxc/{vmid}/config
/nodes/{node}/lxc/{vmid}/status/current
/nodes/{node}/tasks
/storage
```

## `pvesh`

When SSH access is available, prefer `pvesh` over hand-written curl for local Proxmox API inspection. It exposes the same API tree and avoids managing API auth manually.

Examples:

```bash
ssh root@shipyard 'pveversion'
ssh root@shipyard 'pvesh get /version --output-format json'
ssh root@shipyard 'pvesh get / --output-format json'
ssh root@shipyard 'pvesh ls /'
ssh root@shipyard 'pvesh get /nodes --output-format json'
ssh root@shipyard 'pvesh get /cluster/resources --output-format json'
```

Inspect a VM or LXC after identifying its node and VMID:

```bash
ssh root@shipyard 'pvesh get /nodes/shipyard/qemu/<vmid>/config --output-format json'
ssh root@shipyard 'pvesh get /nodes/shipyard/qemu/<vmid>/status/current --output-format json'
ssh root@shipyard 'pvesh get /nodes/shipyard/lxc/<vmid>/config --output-format json'
ssh root@shipyard 'pvesh get /nodes/shipyard/lxc/<vmid>/status/current --output-format json'
```

Ask `pvesh` for endpoint usage:

```bash
ssh root@shipyard 'pvesh usage /nodes/{node}/qemu/{vmid}/config --verbose'
ssh root@shipyard 'pvesh usage /nodes/{node}/lxc/{vmid}/config --verbose'
```

`pvesh usage --returns` can expose return schemas, but some endpoints may hit Perl JSON serialization bugs. If that happens, fall back to `apidoc.js`.

## HTTP API

The API base URL is:

```text
https://shipyard:8006/api2/json/
```

Authenticated `GET /api2/json/` returns child directories like `version`, `cluster`, `nodes`, `storage`, `access`, and `pools`. Unauthenticated API requests usually return `401 No ticket`.

If using an API token, prefer an environment variable and avoid printing the token:

```bash
curl -k \
  -H "Authorization: PVEAPIToken=${PVE_API_TOKEN}" \
  https://shipyard:8006/api2/json/version
```

Ticket authentication exists too, but avoid putting passwords or tickets directly in commands visible in shell history or process lists. API-token auth does not require a CSRF token; ticket-cookie auth requires `CSRFPreventionToken` for `POST`, `PUT`, and `DELETE`.

## Diagnostics Workflow

Start broad, then narrow:

1. Check Proxmox version and node health with `pveversion`, `/version`, `/nodes`, and `/cluster/resources`.
2. Identify whether the target is a QEMU VM or LXC container.
3. Inspect config and current status with the relevant `/qemu/<vmid>/...` or `/lxc/<vmid>/...` endpoint.
4. Inspect recent tasks through `/nodes/<node>/tasks` if an operation failed.
5. For guest-level issues, SSH to the VM/LXC by Tailscale name when known and inspect `systemctl`, `journalctl`, and `podman` logs there.
6. Prefer declarative fixes in this NixOS repository over one-off host mutations.

## Safety

- Treat Proxmox as production infrastructure.
- Never paste secrets, API tokens, tickets, or CSRF tokens into responses.
- Do not change Proxmox state unless the user asked for the change, not merely for investigation.
- If a command could affect availability, say what it will do and ask first.
