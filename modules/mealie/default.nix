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
    services.cloudflare-dns.domains = ["bmealie.rileymathews.com"];

    myNginx.proxies.mealie = {
        listenHost = "bmealie.rileymathews.com";
        backendHost = "http://127.0.0.1:8000";
    };

    virtualisation.oci-containers.containers = {
        mealie = {
            image = "docker.io/searxng/searxng:latest";
            ports = ["8000:8080"];
        };
    };
}
