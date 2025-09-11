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
    ./../../modules/tailscale
    ./../../modules/dns
  ];
  networking.hostName = "nixos-playground";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;

  services.rpcbind.enable = true;
  boot.kernelModules = [ "nfs" ];
  boot.supportedFilesystems = [ "nfs" ];
  fileSystems."/mnt/testing" = {
    device = "nas:/main/testing";
    fsType = "nfs";
    options = ["defaults"];
  };
  services.cloudflare-dns = {
    enable = true;
    domains = [
      "testing.rileymathews.com"
      "another-test.rileymathews.com"
    ];
  };
}

