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
    services.cloudflare-dns.domains = ["immich.rileymathews.com" "pg-immich.rileymathews.com"];

    myNginx.proxies.immich = {
        listenHost = "immich.rileymathews.com";
        backendHost = "http://127.0.0.1:2283";
    };

    systemd.mounts = [{
        what = "nas:/main/immich";
        where = "/mnt/immich";
        type = "nfs";
        options = "defaults";

        # Make it wait for Tailscale
        wantedBy = [ "multi-user.target" ];
        after = [ "tailscale-ready.service" ];
        requires = [ "tailscale-ready.service" ];
    }];

    systemd.services."podman-immich".unitConfig = {
        Requires = [ "mnt-immich.mount" ];
        After = [ "mnt-immich.mount" ];
    };
    systemd.services."podman-transcoding".unitConfig = {
        Requires = [ "mnt-immich.mount" ];
        After = [ "mnt-immich.mount" ];
    };

    age.secrets.immich-credentials-file = {
        file =  ../../secrets/immich-credentials-file.age;
    };

    virtualisation.oci-containers.containers = {
        immich = {
            image = "ghcr.io/immich-app/immich-server:v2.4.1";
            ports = ["2283:2283"];
            volumes = [ 
                "/mnt/immich/uploads:/usr/src/app/upload" 
            ];
            environment = {
                IMMICH_VERSION = "release";
                # password in secrets file
                DB_HOSTNAME = "pg-immich.rileymathews.com";
                DB_USERNAME = "immich";
                IMMICH_WORKERS_INCLUDE = "api";
                REDIS_HOSTNAME = "redis.tailscale.rileymathews.com";
                REDIS_DB_INDEX = "4";
            };
            environmentFiles = [ config.age.secrets.immich-credentials-file.path ];
        };

        transcoding = {
            image = "ghcr.io/immich-app/immich-server:v2.4.1";
            volumes = [ 
                "/mnt/immich/uploads:/usr/src/app/upload" 
            ];
            environment = {
                IMMICH_VERSION = "release";
                # password in secrets file
                DB_HOSTNAME = "pg-immich.rileymathews.com";
                DB_USERNAME = "immich";
                IMMICH_WORKERS_INCLUDE = "microservices";
                REDIS_HOSTNAME = "redis.tailscale.rileymathews.com";
                REDIS_DB_INDEX = "4";
            };
            environmentFiles = [ config.age.secrets.immich-credentials-file.path ];
        };

        database = {
            image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
            ports = [ "5432:5432" ];
            volumes = [ "immich_db_data_volume:/var/lib/postgresql/data" ];
            environment = {
                POSTGRES_INITDB_ARTGS = "--data-checksums";
                POSTGRES_USER = "immich";
                POSTGRES_DATABASE = "immich";
            };
            environmentFiles = [ config.age.secrets.immich-credentials-file.path ];
        };
    };
}
