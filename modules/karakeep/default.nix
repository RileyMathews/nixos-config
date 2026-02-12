{
    config,
    ...
}:
{
    imports = [../caddy-multi-proxy ../dns ../restic-local-appdata];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["karakeep.rileymathews.com" "chrome-karakeep.rileymathews.com"];

    myCaddy.proxies.karakeep = {
        listenHost = "karakeep.rileymathews.com";
        backendHost = "http://127.0.0.1:3000";
    };
    myCaddy.proxies.karakeep-chrome = {
        listenHost = "chrome-karakeep.rileymathews.com";
        backendHost = "http://0.0.0.0:9222";
    };

    age.secrets.karakeep-credentials-file = {
        file =  ../../secrets/karakeep-credentials-file.age;
    };

    services.resticLocalAppdata = {
        enable = true;
        paths = [
            "/var/lib/appdata/karakeep/data"
        ];
    };

    virtualisation.oci-containers.backend = "podman";

    virtualisation.oci-containers.containers.karakeep = {
        image = "ghcr.io/karakeep-app/karakeep:0.30.0";
        ports = ["3000:3000"];
        volumes = ["/var/lib/appdata/karakeep/data:/data"];
        environmentFiles = [ config.age.secrets.karakeep-credentials-file.path ];
        # use network mode host because I couldn't figure out a way to get karakeep
        # to connect to chrome otherwise. It seems like karakeep does some internal
        # resolution logic that then manually calls the
        # ip address instead of going through normal DNS resolution.
        extraOptions = [ "--network=host" ];
        environment = {
            BROWSER_WEB_URL = "http://0.0.0.0:9222";
            NEXTAUTH_URL = "https://karakeep.rileymathews.com";
            DATA_DIR = "/data";
        };
    };

    virtualisation.oci-containers.containers.chrome = {
        image = "gcr.io/zenika-hub/alpine-chrome:124";
        ports = ["9222:9222"];
        cmd = [
            "--no-sandbox"
            "--disable-gpu"
            "--disable-dev-shm-usage"
            "--remote-debugging-address=0.0.0.0"
            "--remote-debugging-port=9222"
            "--hide-scrollbars"
        ];
    };
}
