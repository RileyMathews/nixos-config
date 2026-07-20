{ config, lib, pkgs, ... }:
{
  imports = [ ../caddy-multi-proxy ../dns ];

  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "rilib.rileymathews.com" ];

  myAcme.certs."rilib.rileymathews.com" = {
    hostName = "rilib.rileymathews.com";
    group = "caddy";
    dnsProvider = "cloudflare";
  };

  services.caddy.virtualHosts."rilib.rileymathews.com" = {
    useACMEHost = "rilib.rileymathews.com";
    extraConfig = ''
      root * /var/www/rilib
      encode zstd gzip
      file_server
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/www/rilib 0755 riley riley -"
  ];
}
