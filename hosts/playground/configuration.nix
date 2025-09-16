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
    ./../../modules/nginx-multi-proxy
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
      "whoaminixos.rileymathews.com"
    ];
  };

  myNginx.proxies.whoami1 = {
    listenHost = "testing.rileymathews.com";
    backendHost = "http://127.0.0.1:8000";
  };
  myNginx.proxies.whoami2 = {
    listenHost = "whoaminixos.rileymathews.com";
    backendHost = "http://127.0.0.1:8001";
  };

  virtualisation.podman.enable = true;

  systemd.timers."podman-auto-update".wantedBy = ["multi-user.target"];

  virtualisation.oci-containers.containers = {
    whoami = {
      image = "docker.io/traefik/whoami:latest";
      ports = ["8000:80"];
      extraOptions = [
        "--label" "io.containers.autoupdate=registry"
      ];
    };
    whoami2 = {
      image = "docker.io/traefik/whoami:v1.11";
      ports = ["8001:80"];
      extraOptions = [
        "--label" "io.containers.autoupdate=registry"
      ];
    };
  };
}

