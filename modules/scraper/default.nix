{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [../caddy-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["scraper.rileymathews.com"];

    myCaddy.proxies.scraper = {
        listenHost = "scraper.rileymathews.com";
        backendHost = "http://127.0.0.1:3948";
    };

    virtualisation.oci-containers.containers = {
        scraper = {
            image = "registry.rileymathews.com/rileymathews/scraper:0.0.2";
            ports = ["3948:8080"];
            user = "1000:1000";
        };
    };
}
