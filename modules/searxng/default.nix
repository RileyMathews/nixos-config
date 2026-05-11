{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns ../container-images];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["search.rileymathews.com"];

    myNginx.proxies.asearxng = {
        listenHost = "search.rileymathews.com";
        backendHost = "http://127.0.0.1:8000";
    };

    environment.etc."searxng/settings.yml".text = builtins.readFile ./settings.yml;

    virtualisation.oci-containers.containers = {
        searxng = {
            image = config.myContainerImages.searxng;
            ports = ["8000:8080"];
            volumes = ["/etc/searxng/settings.yml:/etc/searxng/settings.yml:ro"];
            extraOptions = [
                "--label" "io.containers.autoupdate=registry"
            ];
        };
    };
}
