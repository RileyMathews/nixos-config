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
    ./../../modules/immich-ml
    ./../../modules/whisper
    ./../../modules/piper
    ./../../modules/ollama
    ./../../modules/podman-exporter
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
  systemd.timers."podman-auto-update".wantedBy = ["multi-user.target"];
  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
  ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
}
