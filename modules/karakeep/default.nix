{
    config,
    ...
}:
{
    imports = [../caddy-multi-proxy ../dns ../restic-backup];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["karakeep.rileymathews.com" "chrome-karakeep.rileymathews.com"];

    myCaddy.proxies.karakeep = {
        listenHost = "karakeep.rileymathews.com";
        backendHost = "http://127.0.0.1:3000";
    };
    myCaddy.proxies.karakeep-chrome = {
        listenHost = "chrome-karakeep.rileymathews.com";
        backendHost = "http://0.0.0.0:9222";
    };

    age.secrets.karakeep-credentials-file = {
        file =  ../../secrets/karakeep-credentials-file.age;
    };

    services.resticBackup = {
        enable = true;
        backups.karakeep-data = {
            type = "path-list";
            gatusHealthcheckId = "backups_karakeep-backup";
            paths = [
                "/var/lib/appdata/karakeep/data"
            ];
        };
    };

    virtualisation.oci-containers.backend = "podman";
    virtualisation.podman.defaultNetwork.settings.dns_enabled = true;

    virtualisation.oci-containers.containers.karakeep = {
        image = "ghcr.io/karakeep-app/karakeep:0.31.0";
        ports = ["3000:3000"];
        volumes = ["/var/lib/appdata/karakeep/data:/data"];
        environmentFiles = [ config.age.secrets.karakeep-credentials-file.path ];
        # use network mode host because I couldn't figure out a way to get karakeep
        # to connect to chrome otherwise. It seems like karakeep does some internal
        # resolution logic that then manually calls the
        # ip address instead of going through normal DNS resolution.
        networks = [ "podman" ];
        environment = {
            BROWSER_WEB_URL = "http://chrome:9222";
            NEXTAUTH_URL = "https://karakeep.rileymathews.com";
            DATA_DIR = "/data";
            MEILI_ADDR = "http://meilisearch:7700";
        };
    };

    virtualisation.oci-containers.containers.chrome = {
        image = "gcr.io/zenika-hub/alpine-chrome:124";
        networks = [ "podman" ];
        cmd = [
            "--no-sandbox"
            "--disable-gpu"
            "--disable-dev-shm-usage"
            "--remote-debugging-address=0.0.0.0"
            "--remote-debugging-port=9222"
            "--hide-scrollbars"
        ];
    };

    virtualisation.oci-containers.containers.meilisearch = {
        image = "getmeili/meilisearch:v1.13.3";
        environmentFiles = [ config.age.secrets.karakeep-credentials-file.path ];
        networks = [ "podman" ];
        environment = {
            MEILI_NO_ANALYTICS = "true";
        };
        volumes = ["/var/lib/appdata/meilisearch/data:/meili_data"];
    };
}
