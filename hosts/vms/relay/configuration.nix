{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./../../../modules/vms/basic-disk-config.nix
    ./../../../modules/vms/basic-hardware-config.nix
    ./../../../modules/vms/basic-config.nix
    ./../../../modules/tailscale
    ./../../../modules/caddy-multi-proxy
    ./../../../modules/dns
  ];
  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "pve.rileymathews.com" ];
  networking.hostName = "relay";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;

  myCaddy.proxies.rpgweave = {
    listenHost = "rpgweave.com";
    backendHost = "http://rpgweave:80";
    proxyProtocol = true;
  };
  myCaddy.proxies.rpgweave-staging = {
    listenHost = "staging.rpgweave.com";
    backendHost = "http://rpgweave-staging:80";
    proxyProtocol = true;
  };
  myCaddy.proxies.vaultwarden = {
    listenHost = "vaultwarden.rileymathews.com";
    backendHost = "http://worf:8222";
    proxyProtocol = true;
  };
  myCaddy.proxies.thegenerosityco-staging = {
    listenHost = "thegenerosityco-staging.rileymathews.com";
    backendHost = "http://thegenerosityco-staging:8080";
    proxyProtocol = true;
  };
  myCaddy.proxies.papyrd-demo = {
    listenHost = "papyrd-demo.rileymathews.com";
    backendHost = "http://discovery:3847";
    proxyProtocol = true;
  };
}
