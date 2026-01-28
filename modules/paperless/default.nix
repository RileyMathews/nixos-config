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
    services.cloudflare-dns.domains = ["paperless.rileymathews.com"];

    myNginx.proxies.paperless = {
        listenHost = "paperless.rileymathews.com";
        backendHost = "http://127.0.0.1:8008";
    };

    systemd.mounts = [{
        what = "nas:/main/paperless";
        where = "/mnt/paperless";
        type = "nfs";
        options = "defaults";

        # Make it wait for Tailscale
        wantedBy = [ "multi-user.target" ];
        after = [ "tailscale-ready.service" ];
        requires = [ "tailscale-ready.service" ];
    }];

    systemd.services."podman-paperless".unitConfig = {
        Requires = [ "mnt-paperless.mount" ];
        After = [ "mnt-paperless.mount" ];
    };

    age.secrets.paperless-credentials-file = {
        file =  ../../secrets/paperless-credentials-file.age;
    };

    virtualisation.oci-containers.containers = {
        paperless = {
            image = "ghcr.io/paperless-ngx/paperless-ngx:2.20.5";
            ports = ["8008:8000"];
            volumes = [ 
                "/mnt/paperless/data:/usr/src/paperless/data" 
                "/mnt/paperless/media:/usr/src/paperless/media" 
                "/mnt/paperless/export:/usr/src/paperless/export" 
                "/mnt/paperless/consume:/usr/src/paperless/consume" 
            ];
            user = "1000:1000";
            environment = {
                PAPERLESS_REDIS = "redis://redis8.tailscale.rileymathews.com:6379/4";
                PAPERLESS_DBHOST = "pg17.tailscale.rileymathews.com";
                PAPERLESS_URL = "https://paperless.rileymathews.com";
                PAPERLESS_TIME_ZONE = "America/Chicago";
            };
            environmentFiles = [ config.age.secrets.paperless-credentials-file.path ];
        };
    };
}
