{
  modulesPath,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:
{
  imports = [
    ./../../../modules/vms/basic-disk-config.nix
    ./../../../modules/vms/basic-hardware-config.nix
    ./../../../modules/vms/basic-config.nix
    ./../../../modules/vms/swap-config.nix
    ./../../../modules/tailscale
    ./../../../modules/podman-exporter
    ./../../../modules/open-webui
    ./../../../modules/jellyfin
    ./../../../modules/immich
    ./../../../modules/audiobookshelf
    ./../../../modules/copyparty
    ./../../../modules/pinchflat
    ./../../../modules/reverse-health-check
  ];
  networking.hostName = "yamato";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  virtualisation.podman.enable = true;

  fileSystems."/mnt/temp-immich" = {
    device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1";
    fsType = "ext4";
    options = ["defaults" "nofail"];
  };
}
