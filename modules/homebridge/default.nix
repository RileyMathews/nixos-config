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
    services.cloudflare-dns.domains = ["homebridge.rileymathews.com"];
    services.rpcbind.enable = true;
    boot.kernelModules = [ "nfs" ];
    boot.supportedFilesystems = [ "nfs" ];

    myNginx.proxies.homebridge = {
        listenHost = "homebridge.rileymathews.com";
        backendHost = "http://127.0.0.1:8581";
    };

    systemd.mounts = [{
        what = "nas:/main/homebridge";
        where = "/mnt/homebridge";
        type = "nfs";
        options = "defaults";

        # Make it wait for Tailscale
        wantedBy = [ "multi-user.target" ];
        after = [ "tailscale-ready.service" ];
        requires = [ "tailscale-ready.service" ];
    }];

    systemd.services."docker-homebridge".unitConfig = {
        Requires = [ "mnt-homebridge.mount" ];
        After = [ "mnt-homebridge.mount" ];
    };

    virtualisation.oci-containers.containers = {
        homebridge = {
            image = "homebridge/homebridge:latest";
            extraOptions = [ 
                "--network=host" 
                "--label" 
                "io.containers.autoupdate=registry"
            ];
            volumes = [ 
                "/mnt/homebridge:/homebridge"
                "/var/run/dbus:/var/run/dbus"
                "/var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket"
            ];
            environment = {
                ENABLE_AVAHI = "0";
            };
        };
    };
}
