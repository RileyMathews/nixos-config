{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [../caddy-multi-proxy ../dns ../container-images];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["buffer.rileymathews.com"];

    myCaddy.proxies.buffer = {
        listenHost = "buffer.rileymathews.com";
        backendHost = "http://127.0.0.1:3999";
    };

    age.secrets.buffer-credentials-file = {
        file = ../../secrets/buffer-credentials-file.age;
    };

    virtualisation.oci-containers.containers = {
        buffer = {
            image = config.myContainerImages.buffer;
            ports = ["3999:3000"];
            user = "1000:1000";
            environmentFiles = [ config.age.secrets.buffer-credentials-file.path ];
            environment = {
                HTTP_PORT = "3000";
            };
        };
    };
}
