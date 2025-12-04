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
    ./../../modules/docker-registry
  ];
  networking.hostName = "discovery";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
}
