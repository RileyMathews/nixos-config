{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns ../container-images];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["rhc.rileymathews.com"];

    myNginx.proxies.reverse-health-check = {
        listenHost = "rhc.rileymathews.com";
        backendHost = "http://127.0.0.1:8081";
    };

    virtualisation.oci-containers.containers = {
        reverse-health-check = {
            image = config.myContainerImages.reverse-health-check;
            ports = ["8081:8080"];
        };
    };
}
