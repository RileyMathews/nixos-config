{
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns ../restic-local-appdata];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["registry.rileymathews.com"];

    myNginx.proxies.registry = {
        listenHost = "registry.rileymathews.com";
        backendHost = "http://127.0.0.1:5000";
    };

    virtualisation.oci-containers.containers = {
        registry = {
            image = "registry:3.0.0";
            ports = ["5000:5000"];
            volumes = [ "/var/lib/appdata/docker-registry:/var/lib/registry" ];
        };
    };
}
