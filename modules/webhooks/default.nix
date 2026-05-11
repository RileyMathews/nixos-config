{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns ../container-images];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["webhooks.rileymathews.com"];

    myNginx.proxies.webhooks = {
        listenHost = "webhooks.rileymathews.com";
        backendHost = "http://127.0.0.1:8798";
    };

    virtualisation.oci-containers.containers = {
        webhooks = {
            image = config.myContainerImages.webhooks;
            ports = ["8798:8000"];
            user = "1000:1000";
        };
    };
}
