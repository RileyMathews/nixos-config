{
    config,
    modulesPath,
    lib,
    unstablePkgs,
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["nixsearch.rileymathews.com"];

    myNginx.proxies.asearxng = {
        listenHost = "nixsearch.rileymathews.com";
        backendHost = "http://127.0.0.1:8050";
    };

    services.searx.package = unstablePkgs.searxng;
    services.searx.enable = true;
    services.searx.settings = {
        server.port = 8050;
        server.secret_key = "super-secret-key";
    };
}
