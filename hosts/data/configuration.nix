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
    ./../../modules/immich-transcoding
  ];

  networking.hostName = "data";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  # hardware.nvidia.datacenter.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.nvidia.acceptLicense = true;
  hardware.opengl.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false; # Use proprietary drivers
    nvidiaSettings = true;
  };

  boot.kernelModules = [ "nfs" ];
  boot.supportedFilesystems = [ "nfs" ];
  virtualisation.podman.enable = true;
}
