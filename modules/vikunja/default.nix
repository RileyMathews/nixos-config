{ config, ... }:
{
    imports = [
        ../nginx-multi-proxy
        ../dns
        ../restic-local-appdata
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

    services.resticLocalAppdata = {
        enable = true;
        paths = [
            "/var/lib/appdata/vikunja/files"
        ];
    };

    virtualisation.oci-containers.containers = {
        vikunja = {
            image = "vikunja/vikunja:2.1.0";
            ports = [ "3456:3456" ];
            volumes = [ "/var/lib/appdata/vikunja/files:/app/vikunja/files" ];
            user = "1000:1000";
            environment = {
                VIKUNJA_SERVICE_PUBLICURL = "https://vikunja.rileymathews.com";
                VIKUNJA_DATABASE_TYPE = "postgres";
                VIKUNJA_DATABASE_HOST = "pg17.tailscale.rileymathews.com";
                VIKUNJA_DATABASE_PORT = "5432";
                VIKUNJA_DATABASE_USER = "vikunja";
                VIKUNJA_DATABASE_DATABASE = "vikunja";
            };
            environmentFiles = [ config.age.secrets.vikunja-credentials-file.path ];
        };
    };
}
