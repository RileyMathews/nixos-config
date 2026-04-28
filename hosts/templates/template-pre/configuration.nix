{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./../../../modules/vms/basic-disk-config.nix
    ./../../../modules/vms/provisioning-disk-wipe.nix
    ./../../../modules/vms/basic-hardware-config.nix
    ./../../../modules/vms/basic-config.nix
  ];
  networking.hostName = "{{template}}";
  nix.settings.experimental-features = ["nix-command" "flakes"];
}
