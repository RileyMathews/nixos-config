{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./../../modules/vms/basic-disk-config.nix
    ./../../modules/vms/basic-hardware-config.nix
    ./../../modules/vms/basic-config.nix
    ./../../modules/tailscale
    ./../../modules/homeassistant
  ];

  networking.hostName = "bridge";
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  networking.firewall.enable = false;
  services.avahi.enable = true;
}
