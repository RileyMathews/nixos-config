# NAS Debian → NixOS Migration with Immich Continuity

## Goal

Migrate the physical ARM NAS host from Debian to NixOS while keeping the immich application running continuously. The immich upload data (~200GB) will be temporarily moved to a 1TB spinning disk attached to the `yamato` VM, allowing the NAS to be rebuilt offline with zero data loss.

---

## Context

**Current State:**
- NAS is a Friendly Elec CM3588 ARM board running Debian, managed entirely via Ansible
- Immich application is distributed across three VMs: `yamato` (API server), `data` (transcoding/ML workers), `immichdb` (database)
- NAS exports ZFS dataset `main/immich` (~200GB) via NFS to immich services
- Backup coverage is active via restic on `backup-server`

**Why This Migration:**
- Consolidate infrastructure: move NAS from Ansible-managed Debian to NixOS declarative config
- Align with flake-based infrastructure
- Enable future hardware acceleration and optimization

**Key Constraint:**
- CM3588 does not support standard USB boot; requires special installation approach (microSD + U-Boot or UEFI)
- Immich services must remain operational during the NAS rebuild (hence the temporary storage approach)

---

## Scope

### IN
- Migrate NAS filesystem from Debian to NixOS
- Preserve all ZFS datasets and NFS export configuration
- Keep immich running throughout the migration
- Maintain backup coverage

### OUT
- Database migration (immichdb stays as-is, local volume)
- Other NAS-dependent apps (jellyfin, forgejo, etc.) — these are optional and can be shut down during migration
- Changes to immich application code or configuration
- Proxmox host changes (only VM-level disk attachment)

---

## Constraints

### MUST
- Zero data loss on immich uploads
- Immich API server remains accessible throughout migration (via temporary storage)
- All immich data checksums match before/after each copy phase
- New NAS must have identical ZFS dataset structure and NFS exports
- Rollback capability at each phase boundary
- Tailscale hostname `nas` resolves correctly after migration

### MUST NOT
- Stop immich database (`immichdb` VM) — it has no NAS dependency
- Delete temporary storage until immich has been running on new NAS for 24+ hours
- Modify immich application code or container images
- Interrupt backup jobs during migration (they're independent)

---

## Tasks

NOTE FOR AGENTS
when phases have outputs that should be documented
for use in further steps those outputs will be added
with the convention 
-- output: <output here>
A phase may have multiple outputs which will each be on their own line

### Phase 1: Prepare Temporary Storage
**Objective**: Set up the 1TB disk on `yamato` VM, ready to receive immich data

- [x] 1.1 Physically attach 1TB disk to proxmox host (shipyard)
  - What: Connect the 1TB spinning drive to the proxmox host
  - Done when: Disk is visible in proxmox hardware

- [x] 1.2 Attach disk to `yamato` VM via Proxmox UI/API
  - What: Add the 1TB disk as a new SCSI device (will appear as `/dev/vdb`)
  - Proxmox: VM Hardware → Add → Hard Disk → select the 1TB disk
  - Done when: Disk appears in VM as `/dev/vdb` (verify with `lsblk`)
  -- output: disk is /dev/sdb

- [x] 1.3 Identify disk by-id path
  - What: SSH to `yamato`, run `lsblk -o NAME,SERIAL` to get disk serial
  - Command: `ls -la /dev/disk/by-id/ | grep <serial>`
  - Done when: You have the full `/dev/disk/by-id/...` path for the 1TB disk
  -- output: drive serial is `drive-scsi1`
  -- output: drive path is `/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1`

- [x] 1.4 Add disk mount to `yamato` NixOS config
  - Files: `hosts/vms/yamato/configuration.nix`
  - What: Add `fileSystems."/mnt/temp-immich"` entry with:
    - device: `/dev/disk/by-id/...` (from step 1.3)
    - fsType: `ext4`
    - options: `["defaults" "nofail"]`
  - Done when: Config file updated and ready to deploy

- [x] 1.5 Deploy config to `yamato` VM
  - What: `just deploy yamato` from the repo root
  - Done when: Deployment completes without errors and mount point is active

- [x] 1.6 Verify mount is active
  - Commands: `df -h /mnt/temp-immich` and `mount | grep temp-immich`
  - Done when: Mount shows ~1TB available and is listed in mount output

---

### Phase 2: Migrate Immich Data to Temporary Storage
**Objective**: Copy 200GB of immich data from NAS to temporary disk with zero data loss

**Prerequisites**: Phase 1 complete, immich backup verified

- [ ] 2.1 Stop immich API server on `yamato`
  - Command: `systemctl stop podman-immich`
  - Verify: `systemctl status podman-immich` shows inactive
  - Done when: Service is stopped and logs show clean shutdown

- [x] 2.2 Stop immich transcoding on `data` VM
  - Command: SSH to `data`, then `systemctl stop podman-transcoding`
  - Verify: `systemctl status podman-transcoding` shows inactive
  - Done when: Service is stopped

- [x] 2.3 Stop immich ML on `data` VM
  - Command: SSH to `data`, then `systemctl stop podman-immich-ml`
  - Verify: `systemctl status podman-immich-ml` shows inactive
  - Done when: Service is stopped

- [ ] 2.4 Perform rsync from NAS to temporary storage
  - Command: SSH to `yamato`, then `rsync -avhP --delete /mnt/immich/ /mnt/temp-immich/`
  - Done when: rsync completes with no errors and shows final summary

- [ ] 2.5 Verify file count matches
  - Commands:
    - `find /mnt/immich -type f | wc -l` (on yamato)
    - `find /mnt/temp-immich -type f | wc -l` (on yamato)
  - Done when: Both counts are identical

- [ ] 2.6 Spot-check file permissions
  - Commands:
    - `ls -la /mnt/immich` and `ls -la /mnt/temp-immich`
    - `du -sh /mnt/temp-immich` should show ~200GB
  - Done when: Permissions match and disk usage is ~200GB

---

### Phase 3: Reconfigure Immich to Use Temporary Storage
**Objective**: Point immich to the temporary disk so it can resume operation while NAS is offline

**Prerequisites**: Phase 2 complete, data verified

- [ ] 3.1 Update `modules/immich/default.nix`
  - Files: `modules/immich/default.nix`
  - What: Remove NFS mount (nasOci for `10.0.0.110:/immich`), add direct volume mount
  - Volume mount: `/mnt/temp-immich/uploads:/usr/src/app/upload`
  - Comment: `# TEMPORARY: Using local disk during NAS migration`
  - Done when: File is edited and syntax is correct

- [ ] 3.2 Update `modules/immich-transcoding/default.nix`
  - Files: `modules/immich-transcoding/default.nix`
  - What: Remove NFS mount, add direct volume mount to `/mnt/temp-immich/uploads:/usr/src/app/upload`
  - Comment: `# TEMPORARY: Using local disk during NAS migration`
  - Done when: File is edited and syntax is correct

- [ ] 3.3 Create migration checkpoint branch
  - Commands:
    - `git checkout -b migration/nas-temp-storage`
    - `git add modules/immich/default.nix modules/immich-transcoding/default.nix`
    - `git commit -m "WIP: Point immich to temporary storage during NAS migration"`
  - Done when: Commit is created on the migration branch

- [ ] 3.4 Deploy config to `yamato` VM
  - Command: `just deploy yamato`
  - Done when: Deployment completes without errors

- [ ] 3.5 Verify immich API server starts
  - Commands:
    - `systemctl status podman-immich` (should be active)
    - `journalctl -u podman-immich -n 50` (check for errors)
  - Done when: Service is active and logs show clean startup

- [ ] 3.6 Test immich web UI
  - What: Access `https://immich.rileymathews.com` and verify photos are visible
  - Done when: Web UI loads, shows existing photo library, and photos display correctly

- [ ] 3.7 Start immich transcoding on `data` (optional test)
  - Commands: SSH to `data`, then `systemctl start podman-transcoding`
  - Verify: `systemctl status podman-transcoding` shows active
  - Done when: Service is running (optional but good to verify)

---

### Phase 4: Rebuild NAS with NixOS
**Objective**: Migrate the physical NAS from Debian to NixOS with all ZFS datasets and NFS exports

**Prerequisites**: Phase 3 complete, immich verified on temporary storage

**⚠️ Note**: This phase involves two separate tasks that will be planned in a subsequent wardroom session:
1. Create `hosts/vms/nas/configuration.nix` (or `hosts/nas/` if bare-metal pattern differs) with ZFS and NFS server config
2. Install NixOS on the CM3588 hardware using the appropriate method (U-Boot, UEFI, or vendor kernel)

**CM3588 Installation Approaches** (research completed):

- **Path A**: U-Boot + microSD (simplest, but HDMI doesn't work; install headlessly)
  - Reference: [NixOS Wiki: FriendlyELEC CM3588](https://wiki.nixos.org/wiki/NixOS_on_ARM/FriendlyELEC_CM3588)
  - Reference: [Mic92/nixos-aarch64-images](https://github.com/Mic92/nixos-aarch64-images) (official CM3588 image builder)
  - Reference: [blog.psychollama.io: NixOS on a CM3588](https://blog.psychollama.io/nixos-on-a-cm3588/) (real-world install guide with gotchas)

- **Path B**: EDK2 UEFI (recommended for long-term; standard install workflow)
  - Reference: [edk2-porting/edk2-rk3588 releases](https://github.com/edk2-porting/edk2-rk3588/releases) (Platinum-tier CM3588 support)
  - Reference: [NixOS Discourse: CM3588 NAS KIT ZFS Questions](https://discourse.nixos.org/t/friendlyelec-cm3588-nas-kit-nixos-hdmi-uart-and-zfs-encryption-questions/61347) (community experience with EDK2 + ZFS)

- **Path C**: Vendor kernel (full hardware acceleration; uses FriendlyElec BSP kernel)
  - Reference: [YayaADev/nixos-friendlyelec-cm3588](https://github.com/YayaADev/nixos-friendlyelec-cm3588) (vendor kernel flake, Feb 2026, NAS-optimized)

- [ ] 4.1 Create NixOS NAS configuration
  - Files: `hosts/vms/nas/configuration.nix` (or `hosts/nas/configuration.nix`)
  - What: Build configuration from `ansible/host_vars/nas.yml` reference
  - Reference files:
    - `ansible/host_vars/nas.yml` — ZFS datasets and NFS exports
    - `ansible/roles/zfs/tasks/main.yml` — ZFS dataset creation
    - `ansible/roles/nfs/templates/exports.j2` — NFS export configuration
  - Includes: ZFS pool `main` with all datasets, NFS server config, Tailscale, bootloader for CM3588
  - Done when: Configuration file is complete and tested (in separate wardroom session)

- [ ] 4.2 Gather ZFS Pool Info from Current Debian System
  - **⚠️ Do this FIRST, before any changes to the NAS**
  - Commands (on current Debian NAS):
    - `zpool list` (get pool name)
    - `cat /etc/hostid` (get ZFS hostid — you'll need this for NixOS)
    - `lsblk` (confirm drive layout; eMMC is likely mmcblk2)
    - `sudo zpool export <poolname>` (cleanly export the pool)
  - Record: **Pool name**: `[to be filled in]`, **Hostid**: `[to be filled in]`
  - Done when: Pool info is documented and pool is exported

- [ ] 4.3 Build NixOS Image on a Separate Machine
  - Command: `nix build --no-write-lock-file 'github:Mic92/nixos-aarch64-images#cm3588NAS'`
  - Done when: Build completes successfully and `result` directory exists

- [ ] 4.4 Add SSH Key to the Image
  - Commands:
    ```bash
    sudo losetup -fP ./result
    LOOP=$(losetup -l | grep result | awk '{print $1}')
    sudo mkdir -p /mnt/nixos-image
    sudo mount ${LOOP}p3 /mnt/nixos-image
    sudo mkdir -p /mnt/nixos-image/root/.ssh
    sudo cp ~/.ssh/id_ed25519.pub /mnt/nixos-image/root/.ssh/authorized_keys
    sudo chmod 700 /mnt/nixos-image/root/.ssh
    sudo chmod 600 /mnt/nixos-image/root/.ssh/authorized_keys
    sudo umount /mnt/nixos-image
    sudo losetup -d $LOOP
    ```
  - Done when: SSH key is added to the image without errors

- [ ] 4.5 Write Image to SD Card
  - **Option A** (if you have SD reader on build machine):
    - Command: `sudo dd if=./result of=/dev/sdX bs=16M status=progress` (replace sdX with your SD card)
  - **Option B** (transfer to CM3588 and write there):
    - Command: `rsync -avP ./result root@cm3588:/tmp/nixos.img` (on build machine)
    - Then on CM3588: `sudo dd if=/tmp/nixos.img of=/dev/mmcblk1 bs=16M status=progress`
  - Done when: Image is written to SD card without errors

- [ ] 4.6 Boot from SD Card and SSH into Installer
  - What: Insert SD card into CM3588 and reboot
  - Command: `ssh root@<cm3588-ip>` (from build machine)
  - Done when: SSH connection to NixOS installer is successful

- [ ] 4.7 Confirm Drive Layout
  - Command: `lsblk` (on NixOS installer)
  - Verify: eMMC is mmcblk2 (NOT your ZFS drives!)
  - Done when: You've confirmed which device is eMMC

- [ ] 4.8 Wipe and Partition eMMC
  - Commands (on NixOS installer):
    ```bash
    wipefs -a /dev/mmcblk2
    parted -s --align optimal /dev/mmcblk2 mklabel gpt
    parted -s --align optimal /dev/mmcblk2 mkpart 'BOOT' fat32 16MB 512MB
    parted -s --align optimal /dev/mmcblk2 set 1 esp on
    parted -s --align optimal /dev/mmcblk2 mkpart 'ROOT' ext4 512MB 100%
    mkfs.vfat -F32 /dev/mmcblk2p1
    mkfs.ext4 /dev/mmcblk2p2
    ```
  - Done when: Filesystems are created without errors

- [ ] 4.9 Mount and Generate NixOS Config
  - Commands (on NixOS installer):
    ```bash
    mount /dev/mmcblk2p2 /mnt
    mkdir -p /mnt/boot
    mount /dev/mmcblk2p1 /mnt/boot
    nixos-generate-config --root /mnt
    ```
  - Done when: Config is generated at `/mnt/etc/nixos/configuration.nix`

- [ ] 4.10 Edit Configuration with ZFS Support
  - File: `/mnt/etc/nixos/configuration.nix` (on NixOS installer)
  - What: Add ZFS support and your pool configuration
  - Key changes to add:
    ```nix
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;
    
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.extraPools = [ "<poolname>" ];  # from step 4.2
    networking.hostId = "<hostid>";  # from step 4.2
    
    networking.hostName = "nas";
    networking.networkmanager.enable = true;
    
    services.openssh.enable = true;
    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAA... your-key"
    ];
    
    system.stateVersion = "24.11";
    ```
  - Done when: Configuration is updated with ZFS pool name and hostid

- [ ] 4.11 Run nixos-install
  - Command: `nixos-install` (on NixOS installer)
  - What: Install NixOS to eMMC
  - Done when: Installation completes and you set a root password

- [ ] 4.12 Reboot into NixOS on eMMC
  - Command: `reboot` (on NixOS installer)
  - What: Remove SD card during boot so system boots from eMMC
  - Expected: System boots into NixOS on eMMC
  - Done when: NixOS boots successfully and you can SSH in

- [ ] 4.13 SSH into NixOS on eMMC
  - Command: `ssh root@nas` (via Tailscale hostname) or `ssh root@<cm3588-ip>`
  - Done when: SSH connection is successful

- [ ] 4.14 Verify ZFS Pool Imported
  - Commands (on NAS):
    - `zpool status` (should show pool online)
    - If not imported: `zpool import <poolname>`
    - `zfs list` (should show all datasets: main, main/immich, main/jellyfin, etc.)
  - Done when: Pool is online and all datasets are present

- [ ] 4.15 Document NAS IP Address
  - Command: `ip addr show` or `hostname -I` (on the NAS)
  - Record: **NAS IP Address**: `[to be filled in]`
  - Purpose: Fallback if Tailscale hostname resolution has issues
  - Done when: IP is documented

- [ ] 4.16 Verify Tailscale Connectivity
  - Commands (on NAS): `systemctl status tailscale` and `tailscale ip`
  - Done when: Tailscale is active and IP is shown

- [ ] 4.17 Verify NFS Server Configuration
  - Commands (on NAS):
    - `systemctl status nfs-server` (should be active)
    - `exportfs -a` (apply exports)
    - `showmount -e localhost` (list exports)
  - Done when: NFS server is active and exports are listed

- [ ] 4.18 Test NFS Mount from `yamato`
  - Commands (on yamato):
    - `showmount -e nas` (query NAS exports)
    - `mount -t nfs -o vers=4.2 nas:/main /tmp/test-mount` (test mount)
    - `ls -la /tmp/test-mount` (verify readable)
    - `umount /tmp/test-mount` (cleanup)
  - Done when: Mount succeeds and is readable

---

### Phase 5: Migrate Immich Data Back to New NAS
**Objective**: Copy immich data from temporary storage back to the new NAS, verify integrity

**Prerequisites**: Phase 4 complete, NAS NFS is operational

- [ ] 5.1 Stop immich API server on `yamato`
  - Command: `systemctl stop podman-immich`
  - Verify: `systemctl status podman-immich` shows inactive
  - Done when: Service is stopped

- [ ] 5.2 Mount NAS immich dataset on `yamato`
  - Commands (on yamato):
    - `mount -t nfs -o vers=4.2,soft,timeo=150,retrans=2 nas:/main/immich /mnt/nas-immich-new`
    - `mount | grep nas-immich-new` (verify mount is active)
  - Done when: Mount is active and accessible

- [ ] 5.3 Perform rsync from temporary storage to new NAS
  - Command: `rsync -avhP --delete /mnt/temp-immich/ /mnt/nas-immich-new/`
  - Done when: rsync completes with no errors

- [ ] 5.4 Verify file count matches
  - Commands:
    - `find /mnt/temp-immich -type f | wc -l`
    - `find /mnt/nas-immich-new -type f | wc -l`
  - Done when: Both counts are identical

- [ ] 5.5 Verify permissions on NAS
  - Commands:
    - `ls -la /mnt/nas-immich-new`
    - `du -sh /mnt/nas-immich-new` (should show ~200GB)
  - Done when: Permissions are correct and disk usage matches

- [ ] 5.6 Unmount temporary NAS mount
  - Command: `umount /mnt/nas-immich-new`
  - Verify: `mount | grep nas-immich-new` returns nothing
  - Done when: Mount is removed

---

### Phase 6: Reconfigure Immich Back to NAS Storage
**Objective**: Point immich back to the permanent NAS storage, resume full operation

**Prerequisites**: Phase 5 complete, data verified on new NAS

- [ ] 6.1 Update `modules/immich/default.nix`
  - Files: `modules/immich/default.nix`
  - What: Remove temporary volume mount, restore NFS mount via nasOci
  - NFS device: `nas:/main/immich` (or IP if needed; document which is used)
  - Mount point: `/mnt/immich`
  - Remove: `# TEMPORARY:` comment
  - Done when: File is edited and syntax is correct

- [ ] 6.2 Update `modules/immich-transcoding/default.nix`
  - Files: `modules/immich-transcoding/default.nix`
  - What: Remove temporary volume mount, restore NFS mount
  - Remove: `# TEMPORARY:` comment
  - Done when: File is edited and syntax is correct

- [ ] 6.3 Create restoration checkpoint commit
  - Commands:
    - `git add modules/immich/default.nix modules/immich-transcoding/default.nix`
    - `git commit -m "Restore immich to NAS storage after successful migration"`
  - Done when: Commit is created

- [ ] 6.4 Deploy config to `yamato` VM
  - Command: `just deploy yamato`
  - Done when: Deployment completes without errors

- [ ] 6.5 Verify immich API server starts
  - Commands:
    - `systemctl status podman-immich` (should be active)
    - `journalctl -u podman-immich -n 50` (check for errors)
  - Done when: Service is active and logs show clean startup

- [ ] 6.6 Test immich web UI
  - What: Access `https://immich.rileymathews.com` and verify all photos are visible
  - Done when: Web UI loads, shows full photo library, and photos display correctly

- [ ] 6.7 Test immich write access (optional)
  - What: Upload a test photo via the web UI
  - Done when: Photo uploads successfully and appears in library

- [ ] 6.8 Restart immich transcoding on `data`
  - Commands (on data):
    - `systemctl start podman-transcoding`
    - `systemctl status podman-transcoding` (should be active)
  - Done when: Service is running

- [ ] 6.9 Verify NFS mounts are from new NAS
  - Commands:
    - On `yamato`: `mount | grep immich` (should show `nas:/main/immich`)
    - On `data`: `mount | grep immich` (should show `nas:/main/immich`)
  - Done when: Both mounts are from the new NAS

---

### Phase 7: Cleanup and Finalization
**Objective**: Remove temporary storage, document changes, restore normal operations

**Prerequisites**: Phase 6 complete, immich verified on new NAS

- [ ] 7.1 Verify immich stability on new NAS
  - What: Monitor immich for 24+ hours with no issues
  - Done when: No errors in logs and all functionality works

- [ ] 7.2 Unmount temporary storage on `yamato`
  - Command: `umount /mnt/temp-immich`
  - Verify: `mount | grep temp-immich` returns nothing
  - Done when: Mount is removed

- [ ] 7.3 Remove disk mount from `yamato` NixOS config
  - Files: `hosts/vms/yamato/configuration.nix`
  - What: Delete the `fileSystems."/mnt/temp-immich"` entry
  - Done when: Entry is removed and file is ready to deploy

- [ ] 7.4 Commit config cleanup
  - Command: `git commit -m "Remove temporary immich storage mount"`
  - Done when: Commit is created

- [ ] 7.5 Deploy config to `yamato`
  - Command: `just deploy yamato`
  - Done when: Deployment completes without errors

- [ ] 7.6 Detach 1TB disk from `yamato` VM via Proxmox
  - Proxmox: VM Hardware → Remove the `scsi1` device
  - Verify: `lsblk` on `yamato` no longer shows the disk
  - Done when: Disk is detached and no longer visible in VM

- [ ] 7.7 Clean up migration git branch
  - Command: `git branch -d migration/nas-temp-storage` (or keep for reference)
  - Done when: Branch is deleted (optional)

- [ ] 7.8 Update documentation
  - What: Retire Ansible NAS playbooks or mark as archived
  - Update: READMEs/wikis to reference `hosts/vms/nas/configuration.nix` instead of Ansible
  - Done when: Documentation is updated

- [ ] 7.9 Verify backup coverage
  - What: Confirm `backup-server` can mount `nas:/main` and restic job runs
  - Commands (on backup-server):
    - `mount -t nfs nas:/main /mnt/test` (test mount)
    - `umount /mnt/test`
    - Check restic job logs for recent successful run
  - Done when: Backup system works with new NAS

- [ ] 7.10 Restore other NAS-dependent apps
  - What: If jellyfin, forgejo, or other apps were shut down, restart them
  - Done when: All apps are running and can mount their NAS shares

---

## Verification

**After all tasks are complete, run:**
```bash
# Verify immich is fully operational
ssh yamato "systemctl status podman-immich"
ssh yamato "curl -s https://immich.rileymathews.com/api/server/info | jq .version"

# Verify NFS mounts
ssh yamato "mount | grep immich"
ssh data "mount | grep immich"

# Verify backup system
ssh backup-server "systemctl status restic-nas-main"
ssh backup-server "journalctl -u restic-nas-main -n 10"

# Verify NAS is healthy
ssh nas "zpool status"
ssh nas "systemctl status nfs-server"
ssh nas "showmount -e localhost"
```

---

## Rollback Procedures

**If anything goes wrong:**

1. **Before Phase 4** (NAS rebuild not started):
   - Revert git changes: `git checkout modules/immich/default.nix modules/immich-transcoding/default.nix`
   - Restart immich: `systemctl start podman-immich` on `yamato`
   - Data on old NAS is untouched

2. **During Phase 4** (NAS rebuild in progress):
   - Immich is running on temporary storage—no data loss
   - If NAS rebuild fails, troubleshoot or try again
   - Immich can continue on temporary storage indefinitely

3. **During Phase 5** (Data migration back to NAS):
   - If rsync fails, restart on temporary storage and troubleshoot
   - Data on temp storage and old NAS are intact

4. **After Phase 6** (Immich on new NAS):
   - If immich fails, revert git changes and point back to temp storage
   - Data on both NAS and temp storage is intact

**Key principle**: Never delete temporary storage until immich has been running on new NAS for 24+ hours with no issues.

---

## Notes

- **NAS IP Address** (to be documented during Phase 4): `[to be filled in]`
- **NAS Addressing** (to be decided during Phase 6): Will use Tailscale hostname `nas:/main/immich` or IP-based if needed
- **CM3588 Installation Path** (to be chosen during Phase 4): Path A (U-Boot), Path B (UEFI), or Path C (Vendor kernel)

---

## Crew Roles

- **You (Captain)**: Direct the flow, make decisions at phase boundaries
- **Data**: Verification checks (file counts, mount status, backup coverage)
- **LaForge**: Troubleshooting NixOS/ZFS/NFS issues
- **Crusher**: On call if anything breaks unexpectedly
- **O'Brien**: Git commits, Proxmox API operations, deployments

