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

### `scripts/vm_status.py`

Fetch current status for a QEMU VM by VMID or name fragment.

Usage:

```bash
./scripts/vm_status.py [--json] <vmid-or-name-fragment>
```

Behavior:

- VMID input: resolves node from cluster resources and fetches current VM status.
- Name-fragment input: requires exactly one match (same ambiguity handling as `vmid_by_name.py`).
- Default output: concise single-line summary (`status`, `uptime`, `cpu`, `mem`).
- `--json`: prints machine-readable JSON with `vmid`, `name`, `node`, and raw status payload.

Examples:

```bash
./scripts/vm_status.py 2001
./scripts/vm_status.py git
./scripts/vm_status.py --json engineering
```

### `scripts/vm_exists.py`

Resolve and confirm a QEMU VM exists by VMID or name fragment.

Usage:

```bash
./scripts/vm_exists.py [--json] <vmid-or-name-fragment>
```

Behavior:

- Resolves exactly one QEMU VM (`vmid`, `name`, `node`).
- Name-fragment input fails with candidate list when ambiguous.
- Prints a one-line confirmation by default.
- `--json`: outputs `{exists, vmid, name, node}`.

### `scripts/vm_runtime_check.py`

Fetch runtime state plus key config health indicators.

Usage:

```bash
./scripts/vm_runtime_check.py [--json] <vmid-or-name-fragment>
```

Behavior:

- Reads `status/current` and VM config in one call path.
- Reports `status`, `qmpstatus`, `uptime`, `cpu`, memory use, and selected config flags.
- Includes derived fields like `running`, `agent_enabled`, and `onboot`.

### `scripts/vm_agent_check.py`

Check guest-agent responsiveness and common agent calls.

Usage:

```bash
./scripts/vm_agent_check.py [--json] <vmid-or-name-fragment>
```

Behavior:

- Tests guest-agent endpoints: `ping`, `network-get-interfaces`, `get-osinfo`.
- Reports HTTP status and per-check success.
- Extracts first non-loopback/non-link-local IPv4 when available.

### `scripts/vm_tasks_recent.py`

List recent Proxmox tasks associated with a VM.

Usage:

```bash
./scripts/vm_tasks_recent.py [--limit N] [--json] <vmid-or-name-fragment>
```

Behavior:

- Queries recent tasks for the VM and prints action/status timeline.
- Includes `upid`, task `type`, status, user, and start/end timestamps.
- `--limit` is clamped to a safe range.

### `scripts/vm_locks_check.py`

Inspect VM lock state and currently running tasks.

Usage:

```bash
./scripts/vm_locks_check.py [--json] <vmid-or-name-fragment>
```

Behavior:

- Reads VM config lock field (`lock`) and current run/qmp status.
- Lists running cluster tasks tied to the VM.
- Useful for diagnosing blocked operations.

### `scripts/vm_console_tail.py`

Show tail of the most recent VM-related Proxmox task log.

Usage:

```bash
./scripts/vm_console_tail.py [--lines N] [--json] <vmid-or-name-fragment>
```

Behavior:

- Finds the latest relevant VM task (`qmstart`, `qmstop`, etc.) and fetches its log lines.
- Prints tail lines for quick troubleshooting context.
- Notes that this is task-log tail data, not a live serial-console stream.

### `scripts/vm_storage_check.py`

Inspect VM disk attachments and volume presence on storage backends.

Usage:

```bash
./scripts/vm_storage_check.py [--json] <vmid-or-name-fragment>
```

Behavior:

- Parses disk-like config entries (`scsi*`, `virtio*`, `ide*`, etc.).
- Maps each disk to `storage:volume` and checks whether volume is present.
- Reports storage query issues without hiding partial results.

### `scripts/vm_node_pressure.py`

Show resource pressure on the VM's current node.

Usage:

```bash
./scripts/vm_node_pressure.py [--json] <vmid-or-name-fragment>
```

Behavior:

- Reads node CPU, memory, rootfs, load average, and uptime.
- Prints a compact pressure summary for host-side triage.

### `scripts/vm_net_check.py`

Inspect VM NIC config and whether referenced bridges exist on the node.

Usage:

```bash
./scripts/vm_net_check.py [--ping] [--json] <vmid-or-name-fragment>
```

Behavior:

- Parses `net*` config entries (`model`, `mac`, `bridge`, tag/options).
- Verifies each configured bridge/interface exists on the Proxmox node.
- Optional `--ping` attempts reachability to guest primary IPv4 from guest agent data.

### `scripts/vm_power_cycle.py`

Power-cycle with explicit escalation from graceful shutdown to forced stop.

Usage:

```bash
./scripts/vm_power_cycle.py [--yes] [--force] [--soft-timeout S] [--start-timeout S] [--json] <vmid-or-name-fragment>
```

Behavior:

- If running: requests `shutdown` and waits up to `--soft-timeout`.
- If graceful shutdown times out and `--force` is set: issues `stop` and waits.
- Starts VM and waits for running status up to `--start-timeout`.
- `--dry-run` prints planned actions without changing VM power state.
- Prints each action/result step for deterministic automation logs.
