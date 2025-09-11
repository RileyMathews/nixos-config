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
    ./../../modules/nginx-single-proxy
    ./../../modules/tailscale
    ./../../modules/dns
  ];
  networking.hostName = "git";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;

  services.rpcbind.enable = true;
  boot.kernelModules = [ "nfs" ];
  boot.supportedFilesystems = [ "nfs" ];
  fileSystems."/mnt/forgejo" = {
    device = "nas:/main/forgejo";
    fsType = "nfs";
    options = ["defaults"];
  };
  myNginx = {
    enable = true;
    hostName = "git.rileymathews.com";
    reverseProxyAddress = "http://127.0.0.1:3000";
  };
  services.cloudflare-dns = {
    enable = true;
    domains = [
      "git.rileymathews.com"
    ];
  };
}

