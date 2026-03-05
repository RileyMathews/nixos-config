{
    config,
    modulesPath,
    lib,
    unstablePkgs,
    ...
}:
{

    imports = [../nas-oci];

    age.secrets.immich-credentials-file = {
        file =  ../../secrets/immich-credentials-file.age;
    };

    services.nasOci = {
        enable = true;

        mounts.immich = {
            mountPoint = "/mnt/immich";
            device = "10.0.0.139:/immich";
        };

        containers.immich.definition = {
            image = "ghcr.io/immich-app/immich-server:v2.5.6";
            volumes = [ 
                "/mnt/immich/uploads:/usr/src/app/upload" 
            ];
            environment = {
                IMMICH_VERSION = "release";
                # password in secrets file
                DB_HOSTNAME = "immichdb.rileymathews.com";
                DB_USERNAME = "immich";
                IMMICH_WORKERS_INCLUDE = "microservices";
                REDIS_HOSTNAME = "redis8.tailscale.rileymathews.com";
                REDIS_DB_INDEX = "3";
                # GPU-related environment variables
                NVIDIA_VISIBLE_DEVICES = "all";
                NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
            };
            environmentFiles = [ config.age.secrets.immich-credentials-file.path ];
            extraOptions = [
                "--device=nvidia.com/gpu=all"
                "--security-opt=label=disable"
            ];
        };
    };
}
