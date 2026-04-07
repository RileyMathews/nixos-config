{ ... }:
{
  imports = [
    ../caddy-multi-proxy
    ../dns
  ];

  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "syncthing.rileymathews.com" ];

  myCaddy.proxies.syncthing = {
    listenHost = "syncthing.rileymathews.com";
    backendHost = "http://127.0.0.1:8384";
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    settings.gui = {
      address = "127.0.0.1:8384";
      insecureSkipHostcheck = true;
    };
  };
}
