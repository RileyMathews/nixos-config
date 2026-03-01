{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./../../../modules/vms/basic-disk-config.nix
    ./../../../modules/vms/basic-hardware-config.nix
    ./../../../modules/vms/basic-config.nix
    ./../../../modules/tailscale
    ./../../../modules/homeassistant
    ./../../../modules/homebridge
    ./../../../modules/podman-exporter
  ];

  networking.hostName = "bridge";
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  networking.firewall.enable = false;
  services.avahi.enable = true;
  systemd.timers."podman-auto-update".wantedBy = ["multi-user.target"];
}
