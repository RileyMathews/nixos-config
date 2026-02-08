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
    services.cloudflare-dns.domains = ["immich.rileymathews.com"];

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

    age.secrets.immich-credentials-file = {
        file =  ../../secrets/immich-credentials-file.age;
    };

    virtualisation.oci-containers.containers = {
        immich = {
            image = "ghcr.io/immich-app/immich-server:v2.5.3";
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
}
