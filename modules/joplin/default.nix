{ config, lib, ... }:
{
    imports = [
        ../caddy-multi-proxy
        ../dns
    ];

    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = [ "joplin.rileymathews.com" ];

    myCaddy.proxies.joplin = {
        listenHost = "joplin.rileymathews.com";
        backendHost = "http://127.0.0.1:22300";
    };

    age.secrets.joplin-credentials-file = {
        file = ../../secrets/joplin-credentials-file.age;
    };

    virtualisation.oci-containers.containers.joplin = {
        image = "joplin/server:3.6.3";
        ports = [ "22300:22300" ];
        environment = {
            DB_CLIENT = "pg";
            POSTGRES_USER = "joplin";
            POSTGRES_HOST = "pg17.tailscale.rileymathews.com";
            POSTGRES_PORT = "5432";
            POSTGRES_DATABASE = "joplin";
            APP_BASE_URL = "https://joplin.rileymathews.com";
        };
        environmentFiles = [ config.age.secrets.joplin-credentials-file.path ];
    };
}
