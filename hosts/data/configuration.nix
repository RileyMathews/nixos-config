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
  ];
  networking.hostName = "data";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  # myTailscale.enable = true;

  virtualisation.podman.enable = true;
  # systemd.timers."podman-auto-update".wantedBy = ["multi-user.target"];
}
