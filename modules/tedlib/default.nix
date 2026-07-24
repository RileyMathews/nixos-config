{ config, lib, pkgs, ... }:
{
  imports = [ ../caddy-multi-proxy ../dns ];

  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "tedlib.rileymathews.com" ];

  myAcme.certs."tedlib.rileymathews.com" = {
    hostName = "tedlib.rileymathews.com";
    group = "caddy";
    dnsProvider = "cloudflare";
  };

  services.caddy.virtualHosts."tedlib.rileymathews.com" = {
    useACMEHost = "tedlib.rileymathews.com";
    extraConfig = ''
      root * /var/www/tedlib
      encode zstd gzip
      file_server
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/www/tedlib 0755 riley riley -"
  ];
}
