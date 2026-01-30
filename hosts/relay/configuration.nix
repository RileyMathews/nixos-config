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
    ./../../modules/nginx-multi-proxy
    ./../../modules/dns
  ];
  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "pve.rileymathews.com" ];
  networking.hostName = "relay";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;

  myNginx.proxies.rpgweave = {
    listenHost = "rpgweave.com";
    backendHost = "http://rpgweave:80";
    proxyProtocol = true;
  };
  myNginx.proxies.rpgweave-staging = {
    listenHost = "staging.rpgweave.com";
    backendHost = "http://rpgweave-staging:80";
    proxyProtocol = true;
  };
  myNginx.proxies.vaultwarden = {
    listenHost = "vaultwarden.rileymathews.com";
    backendHost = "http://worf:8222";
    proxyProtocol = true;
  };
  myNginx.proxies.thegenerosityco-staging = {
    listenHost = "thegenerosityco-staging.rileymathews.com";
    backendHost = "http://thegenerosityco-staging:8080";
    proxyProtocol = true;
  };
}

