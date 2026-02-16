{ config, ... }:
{
    imports = [
        ../nas-oci
        ../nginx-multi-proxy
        ../dns
    ];

    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = [ "jellyfin.rileymathews.com" ];

    myNginx.proxies.jellyfin = {
        listenHost = "jellyfin.rileymathews.com";
        backendHost = "http://127.0.0.1:8096";
    };

    services.nasOci = {
        enable = true;

        mounts.jellyfin = {
            mountPoint = "/mnt/jellyfin";
            device = "10.0.0.110:/jellyfin";
        };

        containers.jellyfin = {
            definition = {
                image = "lscr.io/linuxserver/jellyfin:latest";
                ports = [ "127.0.0.1:8096:8096" ];
                volumes = [
                    "/mnt/jellyfin/config:/config"
                    "/mnt/jellyfin/media:/data:ro"
                ];
                environment = {
                    PUID = "1000";
                    PGID = "1000";
                    TZ = "America/Chicago";
                    JELLYFIN_PublishedServerUrl = "https://jellyfin.rileymathews.com";
                };
                extraOptions = [
                    "--label" "io.containers.autoupdate=registry"
                ];
            };
        };
    };
}
