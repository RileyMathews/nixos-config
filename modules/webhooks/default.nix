{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["webhooks.rileymathews.com"];

    myNginx.proxies.webhooks = {
        listenHost = "webhooks.rileymathews.com";
        backendHost = "http://127.0.0.1:8798";
    };

    virtualisation.oci-containers.containers = {
        webhooks = {
            image = "registry.rileymathews.com/rileymathews/webhook-processor:0.2.0";
            ports = ["8798:8000"];
            user = "1000:1000";
        };
    };

}
