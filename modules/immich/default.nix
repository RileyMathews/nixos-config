{
    config,
    modulesPath,
    lib,
    unstablePkgs,
    ...
}:
{
    imports = [../nas-oci ../nginx-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["immich.rileymathews.com"];

    myNginx.proxies.immich = {
        listenHost = "immich.rileymathews.com";
        backendHost = "http://127.0.0.1:2283";
    };

    age.secrets.immich-credentials-file = {
        file =  ../../secrets/immich-credentials-file.age;
    };

    services.nasOci = {
        enable = true;

        mounts.immich = {
            mountPoint = "/mnt/immich";
            device = "10.0.0.110:/immich";
        };

        containers.immich = {
            definition = {
                image = "ghcr.io/immich-app/immich-server:v2.5.6";
                ports = ["2283:2283"];
                volumes = [
                    "/mnt/immich/uploads:/usr/src/app/upload"
                ];
                environment = {
                    IMMICH_VERSION = "release";
                    # password in secrets file
                    DB_HOSTNAME = "immichdb.rileymathews.com";
                    DB_USERNAME = "immich";
                    IMMICH_WORKERS_INCLUDE = "api";
                    REDIS_HOSTNAME = "redis8.tailscale.rileymathews.com";
                    REDIS_DB_INDEX = "3";
                };
                environmentFiles = [ config.age.secrets.immich-credentials-file.path ];
            };
        };
    };
}
