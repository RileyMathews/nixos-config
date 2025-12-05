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
    services.cloudflare-dns.domains = ["audiobookshelf.rileymathews.com"];

    myNginx.proxies.audiobookshelf = {
        listenHost = "audiobookshelf.rileymathews.com";
        backendHost = "http://127.0.0.1:13378";
    };

    systemd.services."podman-audiobookshelf".unitConfig = {
        Requires = [ "mnt-audiobookshelf.mount" ];
        After = [ "mnt-audiobookshelf.mount" ];
    };

    systemd.mounts = [{
        what = "nas:/main/audiobookshelf";
        where = "/mnt/audiobookshelf";
        type = "nfs";
        options = "defaults";

        # Make it wait for Tailscale
        wantedBy = [ "multi-user.target" ];
        after = [ "tailscale-ready.service" ];
        requires = [ "tailscale-ready.service" ];
    }];

    virtualisation.oci-containers.containers = {
        audiobookshelf = {
            image = "ghcr.io/advplyr/audiobookshelf:2.31.0";
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
}
