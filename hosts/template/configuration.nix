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
  ];
  networking.hostName = "nixos-test";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };
}

