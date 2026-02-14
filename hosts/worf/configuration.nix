{
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
    ./../../modules/vms/swap-config.nix
    ./../../modules/tailscale
    ./../../modules/vaultwarden
  ];
  networking.hostName = "worf";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
}
