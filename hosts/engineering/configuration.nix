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
    ./../../modules/dns
    ./../../modules/nginx-multi-proxy
  ];
  networking.hostName = "engineering";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "grafana.rileymathews.com" ];

  myNginx.proxies.grafana = {
    listenHost = "grafana.rileymathews.com";
    backendHost = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        domain = "grafana.rileymathews.com";
        http_port = 2342;
        http_addr = "127.0.0.1";
      };
    };
  };

  services.prometheus = {
    enable = true;
    port = 9001;
  };
}
