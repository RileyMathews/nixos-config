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
  networking.hostName = "borg";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  services.cloudflare-dns = {
    enable = true;
    domains = [
      "betasearch.rileymathews.com"
    ];
  };

  myNginx.proxies.searxng = {
    listenHost = "betasearch.rileymathews.com";
    backendHost = "http://127.0.0.1:8000";
  };

  virtualisation.podman.enable = true;

  virtualisation.oci-containers.containers = {
    searxng = {
      image = "docker.io/searxng/searxng:latest";
      ports = ["8000:8080"];
      extraOptions = [
        "--label" "io.containers.autoupdate=registry"
      ];
    };
  };
}
