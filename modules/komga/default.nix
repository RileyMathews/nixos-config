{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [../caddy-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["komga.rileymathews.com"];

    myCaddy.proxies.komga = {
        listenHost = "komga.rileymathews.com";
        backendHost = "http://127.0.0.1:25600";
    };

    systemd.tmpfiles.rules = [
        "d /var/lib/komga/config 0755 riley riley -"
        "d /var/lib/komga/data 0755 riley riley -"
    ];

    virtualisation.oci-containers.containers = {
        komga = {
            image = "gotson/komga";
            ports = ["25600:25600"];
            user = "1000:1000";
            volumes = [
                "/var/lib/komga/config:/config"
                "/var/lib/komga/data:/data"
            ];
            environment = {
                TZ = "America/New_York";
            };
        };
    };
}