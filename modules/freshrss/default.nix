{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [../caddy-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["freshrss.rileymathews.com"];

    myCaddy.proxies.freshrss = {
        listenHost = "freshrss.rileymathews.com";
        backendHost = "http://127.0.0.1:9733";
    };

    age.secrets.freshrss-credentials-file = {
        file = ../../secrets/freshrss-credentials-file.age;
    };

    systemd.tmpfiles.rules = [
        "d /var/www/FreshRSS/data 0755 riley riley -"
    ];

    virtualisation.oci-containers.containers = {
        freshrss = {
            image = "freshrss/freshrss:1.28.1";
            ports = ["9733:80"];
            volumes = [ "/var/www/FreshRSS/data:/var/www/FreshRSS/data" ];
            environment = {
                DB_HOST = "pg17.tailscale.rileymathews.com";
                DB_USER = "freshrss";
                DB_BASE = "freshrss";
                ADMIN_EMAIL = "riley@rileymathews.com";
                BASE_URL = "https://freshrss.rileymathews.com";
                SERVER_DNS = "freshrss.rileymathews.com";
            };
            environmentFiles = [ config.age.secrets.freshrss-credentials-file.path ];
        };
    };

}
