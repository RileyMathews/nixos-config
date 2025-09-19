{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["asearch.rileymathews.com"];

    myNginx.proxies.searxng = {
        listenHost = "asearch.rileymathews.com";
        backendHost = "http://127.0.0.1:8050";
    };

    services.searx.enable = true;
    services.searx.settings.server.port = 8050;
}
