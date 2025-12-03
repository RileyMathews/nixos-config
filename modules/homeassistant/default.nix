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
    services.cloudflare-dns.domains = ["home.rileymathews.com"];

    myNginx.proxies.homeassistant = {
        listenHost = "home.rileymathews.com";
        backendHost = "http://127.0.0.1:8123";
    };

    fileSystems."/mnt/homeassistant" = {
        device = "nas:/main/homeassistant";
        fsType = "nfs";
        options = ["defaults"];
    };

    # systemd.services."podman-homeassistant".unitConfig = {
    #     Requires = [ "mnt-homeassistant.mount" ];
    #     After = [ "mnt-homeassistant.mount" ];
    # };

    virtualisation.oci-containers.containers = {
        homeassistant = {
            image = "linuxserver/homeassistant:version-2025.11.3";
            extraOptions = [ "--network=host" ];
            volumes = [ 
                "/mnt/homeassistant/config:/config"
                "/mnt/homeassistant/media:/media"
            ];
            devices = [ "/dev/ttyACM0:/dev/ttyACM0" ];
            environment = {
                PUID = "1000";
                GUID = "1000";
                TZ = "America/Chicago";
            };
        };
    };
}
