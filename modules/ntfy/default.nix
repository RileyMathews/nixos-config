{
config,
modulesPath,
lib,
...
}:
{
  imports = [../nginx-multi-proxy ../dns];
  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = ["ntfy.rileymathews.com"];

  myNginx.proxies.gatus = {
    listenHost = "ntfy.rileymathews.com";
    backendHost = "http://127.0.0.1:8021";
  };

  services.ntfy-sh.enable = true;
  services.ntfy-sh.settings = {
    listen-http = ":8021";
    base-url = "https://ntfy.rileymathews.com";
    upstream-base-url = "https://ntfy.sh";
  };
}
