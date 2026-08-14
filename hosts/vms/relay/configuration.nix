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
  services.cloudflare-dns.domains = [
    "pve.rileymathews.com"
    "t3code.rileymathews.com"
    "opencode.rileymathews.com"
    "ds9opencode.rileymathews.com"
    "ds9code.rileymathews.com"
    "scottyopencode.rileymathews.com"
    "scottycode.rileymathews.com"
  ];
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
  myCaddy.proxies.papyrd-demo = {
    listenHost = "papyrd-demo.rileymathews.com";
    backendHost = "http://defiant:3847";
    proxyProtocol = true;
  };
  myCaddy.proxies.t3code = {
    listenHost = "t3code.rileymathews.com";
    backendHost = "http://agent-dev:3773";
    proxyProtocol = false;
  };
  myCaddy.proxies.opencode = {
    listenHost = "opencode.rileymathews.com";
    backendHost = "http://agent-dev:4096";
    proxyProtocol = false;
  };
  myCaddy.proxies.ds9opencode = {
    listenHost = "ds9opencode.rileymathews.com";
    backendHost = "http://ds9:4096";
    proxyProtocol = false;
  };
  myCaddy.proxies.ds9code = {
    listenHost = "ds9code.rileymathews.com";
    backendHost = "http://ds9:3773";
    proxyProtocol = false;
  };
  myCaddy.proxies.scottyopencode = {
    listenHost = "scottyopencode.rileymathews.com";
    backendHost = "http://scotty:4096";
    proxyProtocol = false;
  };
  myCaddy.proxies.scottycode = {
    listenHost = "scottycode.rileymathews.com";
    backendHost = "http://scotty:3773";
    proxyProtocol = false;
  };
}
