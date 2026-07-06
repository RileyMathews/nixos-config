---
name: proxmox-vm-disk-resize
description: Use when resizing Proxmox VM disks, growing NixOS guest partitions/LVM/ext4 filesystems, or updating this repo's VM disk size defaults.
---

# Proxmox VM Disk Resize

Use this skill when the user asks to increase a Proxmox QEMU VM disk, expand root storage inside a NixOS VM, or explain whether this repository's `disko` configuration needs to change.

## Repo Context

- Homelab QEMU VMs run on the Proxmox host `shipyard`.
- VM flake output names match Tailscale hostnames, so guest access is usually `ssh root@<hostname>`.
- VM NixOS configs live under `hosts/vms/<hostname>/configuration.nix`.
- Most VM configs import `modules/vms/basic-disk-config.nix`.
- `modules/vms/basic-disk-config.nix` declares `/dev/sda` as the default disk, GPT partitions, root partition size `100%`, LVM VG `pool`, root LV size `100%FREE`, and ext4 mounted at `/`.
- `scripts/provision.py` creates new VMs with `scsi0=${disk_storage}:32,discard=on`, so the initial Proxmox root disk default is `32G` unless overridden later.
- `modules/vms/swap-config.nix` creates an `8192` MiB swapfile by default through `mySwap.swapSize`.

## Safety Rules

- Treat this as production infrastructure.
- Default to read-only inspection first.
- Do not resize disks, reboot VMs, change Proxmox config, or deploy NixOS unless the user explicitly asks for that action and gives the target VM plus desired size change.
- Before any state-changing command, state the exact VM, disk slot, and size change.
- Snapshot or backup first unless the user explicitly declines.
- Never rerun `nixos-anywhere` or the provisioning `disko` wipe flow on an existing VM just to grow a disk.
- Never shrink a disk in this workflow. Shrinking is riskier and needs a separate plan.

## Decide Whether Nix Changes Are Needed

Usually no Nix config change is needed for an existing root disk resize.

- The Proxmox disk allocation is the source of truth for the virtual disk size.
- The existing `disko` layout describes initial installation and says to use all available space, but a normal `nixos-rebuild switch` does not grow an already-created partition/LVM/filesystem.
- The live guest still needs partition, PV, LV, and filesystem expansion after Proxmox presents a larger disk.

Make a Nix change only when one of these applies:

- Future new VMs should default to a larger initial disk. Update `scripts/provision.py`, currently `scsi0=${disk_storage}:32,discard=on`.
- Swap size should change. Set `mySwap.swapSize` in the relevant host config.
- The target storage is a custom extra disk or custom mount declared outside the shared root layout. Inspect that host's config and grow the matching guest device/filesystem instead of assuming `/dev/sda3` and `/dev/pool/root`.

## Read-Only Discovery

Identify the VM and its disk slot:

```bash
ssh root@shipyard 'qm list'
ssh root@shipyard 'qm config <vmid>'
```

If using repository helpers and `PROXMOX_API_TOKEN` is available:

```bash
python3 scripts/vm_storage_check.py <vm-name-or-vmid>
python3 scripts/vm_status.py <vm-name-or-vmid>
```

Inspect guest layout:

```bash
ssh root@<hostname> 'lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS'
ssh root@<hostname> 'findmnt /'
ssh root@<hostname> 'pvs && vgs && lvs'
ssh root@<hostname> 'df -h /'
```

Expected root layout for the shared VM module is typically:

```text
/dev/sda
/dev/sda1 BIOS boot
/dev/sda2 ESP mounted at /boot
/dev/sda3 LVM PV
/dev/pool/root ext4 mounted at /
```

## Resize Workflow

Use this for the common root disk case where Proxmox disk `scsi0` backs guest `/dev/sda`, partition 3 is the LVM PV, and `/dev/pool/root` is `/`.

1. Snapshot or back up the VM.
2. Grow the Proxmox virtual disk.
3. Rescan or reboot if the guest does not see the larger disk.
4. Grow the guest partition.
5. Grow the LVM PV.
6. Grow the LV and ext4 filesystem.
7. Verify `lsblk`, LVM, and `df` output.

State-changing Proxmox resize example:

```bash
ssh root@shipyard 'qm resize <vmid> scsi0 +50G'
```

Use `+50G` to add 50 GiB. Do not pass an absolute size unless you have verified the intended Proxmox semantics.

Guest expansion commands:

```bash
ssh root@<hostname> 'nix shell nixpkgs#cloud-utils -c growpart /dev/sda 3'
ssh root@<hostname> 'pvresize /dev/sda3'
ssh root@<hostname> 'lvextend -r -l +100%FREE /dev/pool/root'
```

Verification commands:

```bash
ssh root@<hostname> 'lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS'
ssh root@<hostname> 'pvs && vgs && lvs'
ssh root@<hostname> 'df -h /'
```

## If The Guest Does Not See The New Size

Check the kernel-visible disk size:

```bash
ssh root@<hostname> 'blockdev --getsize64 /dev/sda && lsblk -b /dev/sda'
```

Try a SCSI rescan:

```bash
ssh root@<hostname> 'for host in /sys/class/scsi_host/host*; do echo "- - -" > "$host/scan"; done'
```

If the guest still does not see the larger size, ask before rebooting:

```bash
ssh root@<hostname> 'systemctl reboot'
```

After the VM returns, rerun `lsblk` and continue with `growpart`, `pvresize`, and `lvextend -r`.

## Troubleshooting

- If `growpart` is missing, run it through `nix shell nixpkgs#cloud-utils -c growpart ...` rather than installing packages imperatively.
- If `growpart /dev/sda 3` fails, stop and inspect `lsblk`, `parted /dev/sda print`, and the host's Nix config. Do not guess the partition number.
- If `pvresize` says the PV is unchanged, confirm the partition grew and that the guest sees the larger parent disk.
- If `lvextend -r` fails, inspect `vgs` for free extents and `findmnt /` for the filesystem type.
- If the filesystem is not ext4 or the LV path is different, adapt the filesystem grow command to the actual layout.
- If the target is an extra data disk, grow the Proxmox disk slot that maps to that device and expand that device's partition/filesystem, not `/dev/pool/root`.

## Reporting Back

Summarize:

- VM name and VMID.
- Proxmox disk slot resized and amount added.
- Guest device, partition, PV, LV, and filesystem expanded.
- Final `df -h /` size and any reboot performed.
- Any Nix config changes made or explicitly not needed.
