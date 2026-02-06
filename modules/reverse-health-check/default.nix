{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["rhc.rileymathews.com"];

    myNginx.proxies.reverse-health-check = {
        listenHost = "rhc.rileymathews.com";
        backendHost = "http://127.0.0.1:8081";
    };

    virtualisation.oci-containers.containers = {
        reverse-health-check = {
            image = "registry.rileymathews.com/rileymathews/reverse-health-check:0.0.1-alpha";
            ports = ["8081:8080"];
        };
    };
}
