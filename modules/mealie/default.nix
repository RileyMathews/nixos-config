{
    config,
    modulesPath,
    lib,
    unstablePkgs,
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["mealie.rileymathews.com"];

    myNginx.proxies.mealie = {
        listenHost = "mealie.rileymathews.com";
        backendHost = "http://127.0.0.1:9000";
    };

    fileSystems."/mnt/mealie" = {
        device = "nas:/main/mealie";
        fsType = "nfs";
        options = ["defaults"];
    };

    systemd.services."podman-mealie".unitConfig = {
        Requires = [ "mnt-mealie.mount" ];
        After = [ "mnt-mealie.mount" ];
    };

    age.secrets.mealie-credentials-file = {
        file =  ../../secrets/mealie-credentials-file.age;
    };

    virtualisation.oci-containers.containers = {
        mealie = {
            image = "ghcr.io/mealie-recipes/mealie:v3.5.0";
            ports = ["9000:9000"];
            volumes = [ "/mnt/mealie/app/data:/app/data" ];
            user = "1000:1000";
            environment = {
                ALLOW_SIGNUP = "true";
                PUID = "1000";
                GUID = "1000";
                TZ = "America/Chicago";
                DB_ENGINE = "postgres";
                POSTGRES_USER = "mealie";
                POSTGRES_SERVER = "pg17.tailscale.rileymathews.com";
                POSTGRES_PORT = "5432";
                POSTGRES_DB = "mealie";
                MAX_WORKERS = "1";
                WEB_CONCURRENCY = "1";
                BASE_URL = "bmealie.rileymathews.com";
                TOKEN_TIME = "720";
            };
            environmentFiles = [ config.age.secrets.mealie-credentials-file.path ];
        };
    };
}
