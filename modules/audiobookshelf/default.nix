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
    services.cloudflare-dns.domains = ["audiobookshelf.rileymathews.com"];

    myNginx.proxies.audiobookshelf = {
        listenHost = "audiobookshelf.rileymathews.com";
        backendHost = "http://127.0.0.1:13378";
    };

    services.nasOci = {
        enable = true;

        mounts.audiobookshelf = {
            mountPoint = "/mnt/audiobookshelf";
            device = "nas:/main/audiobookshelf";
        };

        containers.audiobookshelf = {
            definition = {
                image = "ghcr.io/advplyr/audiobookshelf:2.32.1";
                ports = ["13378:80"];
                volumes = [
                    "/mnt/audiobookshelf/audiobooks:/audiobooks"
                    "/mnt/audiobookshelf/podcasts:/podcasts"
                    "/mnt/audiobookshelf/config:/config"
                    "/mnt/audiobookshelf/metadata:/metadata"
                ];
                environment = {
                    TZ = "America/Chicago";
                    ACCESS_TOKEN_EPIRY = "31557600";
                    REFRESH_TOKEN_EPIRY = "31557600";
                };
            };
        };
    };
}
