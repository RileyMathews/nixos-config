{ config, lib, pkgs, ... }:
{
  imports = [ ../caddy-multi-proxy ../dns ];

  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "agent.rileymathews.com" ];

  myAcme.certs."agent.rileymathews.com" = {
    hostName = "agent.rileymathews.com";
    group = "caddy";
    dnsProvider = "cloudflare";
  };

  services.caddy.virtualHosts."agent.rileymathews.com" = {
    useACMEHost = "agent.rileymathews.com";
    extraConfig = ''
      root * /var/www/agent
      encode zstd gzip
      try_files {path} /200.html
      file_server
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/www/agent 0755 riley riley -"
  ];
}
