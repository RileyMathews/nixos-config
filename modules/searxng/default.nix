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
    services.cloudflare-dns.domains = ["search.rileymathews.com"];

    myNginx.proxies.asearxng = {
        listenHost = "search.rileymathews.com";
        backendHost = "http://127.0.0.1:8000";
    };

    virtualisation.oci-containers.containers = {
        searxng = {
            image = "docker.io/searxng/searxng:latest";
            ports = ["8000:8080"];
            extraOptions = [
                "--label" "io.containers.autoupdate=registry"
            ];
        };
    };
}
