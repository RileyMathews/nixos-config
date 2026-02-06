{
    config,
    modulesPath,
    lib,
    unstablePkgs,
    ...
}:
{
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

    systemd.services."podman-transcoding".unitConfig = {
        Requires = [ "mnt-immich.mount" ];
        After = [ "mnt-immich.mount" ];
    };

    age.secrets.immich-credentials-file = {
        file =  ../../secrets/immich-credentials-file.age;
    };

    virtualisation.oci-containers.containers = {
        transcoding = {
            image = "ghcr.io/immich-app/immich-server:v2.5.3";
            volumes = [ 
                "/mnt/immich/uploads:/usr/src/app/upload" 
            ];
            environment = {
                IMMICH_VERSION = "release";
                # password in secrets file
                DB_HOSTNAME = "pg-immich.rileymathews.com";
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
