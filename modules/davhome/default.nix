{
    config,
    ...
}:
{
    imports = [../caddy-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["davhome.rileymathews.com"];

    myCaddy.proxies.davhome = {
        listenHost = "davhome.rileymathews.com";
        backendHost = "http://127.0.0.1:4010";
    };

    age.secrets.davhome-credentials-file = {
        file = ../../secrets/davhome-credentials-file.age;
    };

    virtualisation.oci-containers.containers = {
        davhome = {
            image = "registry.rileymathews.com/rileymathews/davhome:0.0.18-alpha";
            ports = ["4010:8000"];
            user = "1000:1000";
            environmentFiles = [ config.age.secrets.davhome-credentials-file.path ];
            environment = {
                POSTGRES_DB = "davhome";
                POSTGRES_USER = "davhome";
                POSTGRES_HOST = "pg17.tailscale.rileymathews.com";
                POSTGRES_PORT = "5432";
                WEB_HOST = "davhome.rileymathews.com";
            };
        };
    };
}
