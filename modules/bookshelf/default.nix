{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [../caddy-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["bookshelf.rileymathews.com"];

    myCaddy.proxies.bookshelf = {
        listenHost = "bookshelf.rileymathews.com";
        backendHost = "http://127.0.0.1:3847";
    };

    systemd.tmpfiles.rules = [
        "d /var/lib/bookshelf/data 0755 riley riley -"
    ];
    age.secrets.bookshelf-credentials-file = {
        file = ../../secrets/bookshelf-credentials-file.age;
    };

    virtualisation.oci-containers.containers = {
        bookshelf = {
            image = "registry.rileymathews.com/rileymathews/bookshelf:0.0.3";
            ports = ["3847:3000"];
            user = "1000:1000";
            volumes = ["/var/lib/bookshelf/data:/app/storage"];
            environmentFiles = [ config.age.secrets.bookshelf-credentials-file.path ];
        };
    };
}
