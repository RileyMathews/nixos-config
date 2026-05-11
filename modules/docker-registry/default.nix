{
    config,
    ...
}:
{
    imports = [../caddy-multi-proxy ../dns ../container-images];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["registry.rileymathews.com"];

    myCaddy.proxies.registry = {
        listenHost = "registry.rileymathews.com";
        backendHost = "http://127.0.0.1:5000";
    };

    virtualisation.oci-containers.containers = {
        registry = {
            image = config.myContainerImages.docker-registry;
            ports = ["5000:5000"];
            volumes = [ "/var/lib/appdata/docker-registry:/var/lib/registry" ];
        };
    };
}
