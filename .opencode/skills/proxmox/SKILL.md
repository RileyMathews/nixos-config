---
name: proxmox
description: Use local scripts to manage Proxmox VMs by VMID or name
license: MIT
compatibility: opencode
metadata:
  audience: agents
  workflow: homelab
---

## What I do

- Use repository scripts for routine Proxmox VM operations.
- Prefer VMID-based actions for deterministic behavior.
- Resolve VMIDs from names when needed before taking action.

## When to use me

Use this skill whenever a task involves provisioning, managing, or troubleshooting Proxmox VMs in this repo.

Always use scripts in `scripts/` first instead of ad-hoc API calls.

## Prerequisites

- Run commands from the repo root.
- Ensure `PROXMOX_API_TOKEN` is set in the environment.
- Optional: set `PROXMOX_NODE` (defaults to `shipyard` in scripts that use it).
- Optional: set `PROXMOX_DEBUG=0` for quieter output.

## Script usage

### `scripts/vmid_by_name.py`

Find a VMID by partial VM name (substring match, case-sensitive).

Usage:

```bash
./scripts/vmid_by_name.py <name-fragment>
```

Behavior:

- Exactly one match: prints only VMID to stdout.
- No matches: exits non-zero with an error.
- Multiple matches: exits non-zero and prints candidates (`vmid`, `name`, `node`).

Examples:

```bash
./scripts/vmid_by_name.py git
PROXMOX_DEBUG=0 ./scripts/vmid_by_name.py engineering
```

### `scripts/reset_vm.py`

Force-reset a VM by VMID (useful when guest is frozen/stuck).

Usage:

```bash
./scripts/reset_vm.py [--yes] <vmid>
```

Behavior:

- Default: prompts for confirmation.
- `--yes`: non-interactive reset (automation-friendly).
- Resolves VM name first, then calls Proxmox `status/reset`.

Examples:

```bash
./scripts/reset_vm.py 2001
./scripts/reset_vm.py --yes 2001
```

## Recommended workflow

1. Resolve VMID by name fragment:

```bash
vmid=$(./scripts/vmid_by_name.py git)
```

2. Reset the VM:

```bash
./scripts/reset_vm.py --yes "$vmid"
```
