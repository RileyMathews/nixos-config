{
    config,
    modulesPath,
    lib,
    unstablePkgs,
    ...
}:
{
    age.secrets.immich-credentials-file = {
        file =  ../../secrets/immich-credentials-file.age;
    };

    virtualisation.oci-containers.containers = {
        machine-learning = {
            image = "ghcr.io/immich-app/immich-machine-learning:v2.5.2-cuda";
            environment = {
                IMMICH_VERSION = "release";
                # password in secrets file
                DB_HOSTNAME = "pg-immich.rileymathews.com";
                DB_USERNAME = "immich";
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
            ports = [ "3003:3003" ];
        };
    };
}
