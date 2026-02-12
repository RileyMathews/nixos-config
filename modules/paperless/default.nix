{
    config,
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns ../restic-local-appdata];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["paperless.rileymathews.com"];

    myNginx.proxies.paperless = {
        listenHost = "paperless.rileymathews.com";
        backendHost = "http://127.0.0.1:8008";
    };

    age.secrets.paperless-credentials-file = {
        file =  ../../secrets/paperless-credentials-file.age;
    };

    virtualisation.oci-containers.containers = {
        paperless = {
            image = "ghcr.io/paperless-ngx/paperless-ngx:2.20.6";
            ports = ["8008:8000"];
            volumes = [ 
                "/var/lib/appdata/paperless/data:/usr/src/paperless/data"
                "/var/lib/appdata/paperless/media:/usr/src/paperless/media"
                "/var/lib/appdata/paperless/export:/usr/src/paperless/export"
                "/var/lib/appdata/paperless/consume:/usr/src/paperless/consume"
            ];
            user = "1000:1000";
            environment = {
                PAPERLESS_REDIS = "redis://redis8.tailscale.rileymathews.com:6379/4";
                PAPERLESS_DBHOST = "pg17.tailscale.rileymathews.com";
                PAPERLESS_URL = "https://paperless.rileymathews.com";
                PAPERLESS_TIME_ZONE = "America/Chicago";
                PAPERLESS_CONSUMER_POLLING = "5";
            };
            environmentFiles = [ config.age.secrets.paperless-credentials-file.path ];
        };
    };

    services.resticLocalAppdata = {
        enable = true;
        paths = [
            "/var/lib/appdata/paperless/data"
            "/var/lib/appdata/paperless/media"
            "/var/lib/appdata/paperless/export"
        ];
    };
}
