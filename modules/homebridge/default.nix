{
    config,
    modulesPath,
    lib,
    unstablePkgs,
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns ../restic-local-appdata];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["homebridge.rileymathews.com"];

    myNginx.proxies.homebridge = {
        listenHost = "homebridge.rileymathews.com";
        backendHost = "http://127.0.0.1:8581";
    };

    services.resticLocalAppdata = {
        enable = true;
        paths = [
            "/var/lib/appdata/homebridge"
        ];
    };

    virtualisation.oci-containers.containers = {
        homebridge = {
            image = "docker.io/homebridge/homebridge:latest";
            extraOptions = [ 
                "--network=host" 
                "--label" 
                "io.containers.autoupdate=registry"
            ];
            volumes = [ 
                "/var/lib/appdata/homebridge:/homebridge"
                "/var/run/dbus:/var/run/dbus"
                "/var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket"
            ];
            environment = {
                ENABLE_AVAHI = "0";
            };
        };
    };
}
