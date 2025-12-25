{
  config,
  modulesPath,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:
{
  imports = [
    ./../../modules/vms/basic-disk-config.nix
    ./../../modules/vms/basic-hardware-config.nix
    ./../../modules/vms/basic-config.nix
    ./../../modules/tailscale
  ];

  networking.hostName = "data";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  # hardware.nvidia.datacenter.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = false;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.nvidia.acceptLicense = true;

  virtualisation.podman.enable = true;
}
