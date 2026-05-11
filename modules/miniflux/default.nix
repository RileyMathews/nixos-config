{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [../caddy-multi-proxy ../dns ../container-images];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["miniflux.rileymathews.com"];

    myCaddy.proxies.miniflux = {
        listenHost = "miniflux.rileymathews.com";
        backendHost = "http://127.0.0.1:9732";
    };

    age.secrets.miniflux-env-file = {
        file = ../../secrets/miniflux-env-file.age;
    };

    virtualisation.oci-containers.containers = {
        miniflux = {
            image = config.myContainerImages.miniflux;
            ports = ["9732:8080"];
            user = "1000:1000";
            environmentFiles = [ config.age.secrets.miniflux-env-file.path ];
        };
    };

}
