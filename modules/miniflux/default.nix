{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["miniflux.rileymathews.com"];

    myNginx.proxies.miniflux = {
        listenHost = "miniflux.rileymathews.com";
        backendHost = "http://127.0.0.1:8080";
    };

    services.miniflux.enable = true;
    age.secrets.miniflux-env-file = {
        file = ../../secrets/miniflux-env-file.age;
        mode = "0400";
        owner = "miniflux";
        group = "miniflux";
    };
    services.miniflux.adminCredentialsFile = config.age.secrets.miniflux-env-file.path;
    services.miniflux.createDatabaseLocally = false;
    systemd.services."miniflux".after = [ "network.target" "run-agenix.d.mount" ];
    systemd.services."miniflux".requires = [ "run-agenix.d.mount" ];
}
