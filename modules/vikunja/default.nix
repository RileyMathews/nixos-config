{ config, lib, ... }:
{
    imports = [
        ../nas-oci
        ../nginx-multi-proxy
        ../dns
    ];

    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = [ "vikunja.rileymathews.com" ];

    myNginx.proxies.vikunja = {
        listenHost = "vikunja.rileymathews.com";
        backendHost = "http://127.0.0.1:3456";
    };

    age.secrets.vikunja-credentials-file = {
        file = ../../secrets/vikunja-credentials-file.age;
    };

    services.nasOci = {
        enable = true;

        mounts.vikunja = {
            mountPoint = "/mnt/vikunja";
            device = "nas:/vikunja";
        };

        containers.vikunja = {
            definition = {
                image = "vikunja/vikunja:0.24.6";
                ports = [ "3456:3456" ];
                volumes = [ "/mnt/vikunja/files:/app/vikunja/files" ];
                environment = {
                    VIKUNJA_SERVICE_PUBLIC_URL = "https://vikunja.rileymathews.com";
                    VIKUNJA_DATABASE_TYPE = "postgres";
                    VIKUNJA_DATABASE_HOST = "pg17.tailscale.rileymathews.com";
                    VIKUNJA_DATABASE_PORT = "5432";
                    VIKUNJA_DATABASE_USER = "vikunja";
                    VIKUNJA_DATABASE_DATABASE = "vikunja";
                };
                environmentFiles = [ config.age.secrets.vikunja-credentials-file.path ];
            };
        };
    };
}

