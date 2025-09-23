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
  ];
  networking.hostName = "backup-server";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
}

