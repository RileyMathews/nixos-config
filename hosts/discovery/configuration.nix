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
    ./../../modules/mealie
  ];
  networking.hostName = "discovery";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
}
